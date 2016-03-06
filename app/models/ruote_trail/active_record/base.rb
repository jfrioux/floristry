module RuoteTrail::ActiveRecord
  class Base < ActiveRecord::Base
    after_initialize :include_configured_mixin

    self.abstract_class = true

    include RuoteTrail::CommonMixin
    include RuoteTrail::ExpressionMixin
    include RuoteTrail::LeafExpressionMixin

    ATTRIBUTES_TO_REMOVE = %w(id __feid__ __workitem__ created_at updated_at )

    after_find :init_fei

    attr_accessor :era, :fei

    delegate :trigger!, :available_events, to: :state_machine

    def initialize(attributes = nil, options = {})

      super(attributes, options)
    end

    def include_configured_mixin

      mixin = RuoteTrail.configuration.add_active_record_base_behavior
      self.class.send(:include, mixin) if mixin
    end

    # The workflow engine pass the workitem through this method
    #
    # Save the workitem as an special attribute to be merged at proceed. Bypassing validation is necessary
    # since some Participant's model may have attributes that aren't currently present/valid.
    #
    def self.create(wi_h)

      wi_h['__workitem__'] = JSON.generate(wi_h)
      wi_h['__feid__'] = FlowExpressionId.new(wi_h['fei'].symbolize_keys).to_feid({ no_subid: true })
      wi_h['participant_state'] = StateMachine.initial_state # TODO move to ruote-trail-extensions
      wi_h.keep_if { |k, v| self.column_names.include?(k) }

      obj = new(wi_h)
      obj.save({validate: false})
      obj
    end

    def fields(f)

      init_workitem unless @workitem
      @workitem['fields'][f]
    end

    def wf_name # TODO rename name. Actually, seems like this should in wf, not in wi but
                # maybe there's a reason why it's in wi.workitem (not wi.workitem.fields)

      init_workitem unless @workitem
      @workitem['wf_name']
    end

    def launched_at

      init_workitem unless @workitem
      @workitem['wf_launched_at']
    end

    def class_name

      self.class.to_s
    end

    def participant_name

      init_workitem unless @workitem
      @workitem['participant_name']
    end
    alias_method :name, :participant_name

    # ActiveRecords participants can be search by their Rails ID or Workflow id (feid)
    #
    # This is required since the information in hand from a Workflow perspective is always the
    # Workflow ID, not it's Rails representation.
    #
    def self.find id

      obj = (id.is_a? Integer) ? self.where(id: id).first : self.where(__feid__: id).first
      obj || raise(ActiveRecord::RecordNotFound)
    end

    def email # TODO move to ruote-trail-extensions

      'opensec@mantor.org' #TODO use a constant
    end

    def save(*) #TODO move to ruote-trail-extensions

      trigger!(:open) if self.respond_to?(:participant_state) && participant_state == StateMachine.initial_state
      super
    end

    def update_attributes(*)

      trigger!(:start) if participant_state == :open.to_s
      super
    end

    def fei=(fei)

      @fei = fei
      write_attribute(:__feid__, @fei.to_feid)
    end

    def image() false end

    # If proceeding, merge back attributes within saved workitem and reply to Workflow Engine
    def proceed #TODO should be atomic

      receiver = RuoteTrail::ActiveRecord::Receiver.new(RuoteTrail::WorkflowEngine.engine)
      receiver.proceed(merged_wi)

      # TODO this sucks ass!
      # The trail seems to be written each time ruote 'steps' (each 0.8s).
      # Food for thought - If nothing better: Could we emulate atomicity by simply increasing the expid?
      sleep(1)
    end

    def state_machine # TODO move to ruote-trail-extensions

      @state_machine ||= StateMachine.new(self)
    end

    # The state saved in our participant is the current_state
    def current_state

      participant_state
    end

    protected

    def init_workitem

      @workitem = JSON.parse(__workitem__)
    end

    def init_fei

      @fei = FlowExpressionId.new(__feid__)
    end

    def timestamp

      Time.current.utc.strftime('%Y-%m-%d %H:%M:%S %6N %Z')
    end

    # Provide the original wi with fields merged with model's attributes
    #
    # The wi submitted by the workflow engine is kept untouched in the __workitem__ field.
    # We merge every attributes except a few back within the workitem.
    def merged_wi

      wi = JSON.parse(attributes['__workitem__'])

      # TODO It doesn't make sense to keep the __feid__ attribute within the workitem once we get out of ActiveRecord.
      # The Expression is supposed to have all this info (expids).
      #
      # new_attrs = attributes.keys - ATTRIBUTES_TO_REMOVE
      new_attrs = attributes.reject { |k, v| %w(id __workitem__ created_at updated_at).include? k }

      wi['fields'].merge!(new_attrs)
      wi['fields']['proceeded_at'] = timestamp

      wi
    end
  end

  class StateMachine # TODO move to ruote-trail-extensions
    include Statesman::Machine
    include Statesman::Events

    state :upcoming, initial: true
    state :open
    state :in_progress
    state :late
    state :closed
    state :completed_with_issues

    event :open do
      transition from: :upcoming,     to: :open
      transition from: :open,         to: :open
    end

    event :start do
      transition from: :open,         to: :in_progress
    end

    event :proceed do
      transition from: :in_progress,  to: :closed
      transition from: :late,         to: :closed
      transition from: :closed,       to: :closed
    end

    event :proceed_with_issues do
      transition from: :in_progress,  to: :completed_with_issues
      transition from: :late,         to: :completed_with_issues
    end

    event :late do
      transition from: :late,          to: :late
      transition from: :open,          to: :late
      transition from: :in_progress,   to: :late
    end

    # This avoids the default behavior which is to check in the transition history,
    # in order to return the latest transition 'to_state'.
    def current_state(force_reload: false)

      @object.participant_state
    end

    after_transition do |object, transition|

      object.update_attribute(:participant_state, transition.to_state)
    end
  end
end

# Must be done outside of initialize, since we are dealing with class methods.
mixin = RuoteTrail.configuration.add_active_record_base_behavior
RuoteTrail::ActiveRecord::Base.send(:extend, "#{mixin}::ClassMethods".constantize) if mixin