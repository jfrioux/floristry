module ActiveTrail

  class << self
    attr_accessor :configuration
  end

  def self.configure

    self.configuration ||= Configuration.new

    yield(configuration)
  end

  class Configuration

    attr_accessor :add_leaf_expression_behavior,
                  :add_branch_expression_behavior,
                  :add_expression_behavior,
                  :add_workflow_behavior,
                  :add_active_record_base_behavior
  end
end