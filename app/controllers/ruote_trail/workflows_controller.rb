module RuoteTrail
  class WorkflowsController < ::ApplicationController
    # layout 'application'

    def index

      @wfs = Workflow.all
    end

    def edit

      @wf = Workflow.find(params[:id])
    end

    def update

      @wf = Workflow.find(params[:id])
      if @wf.wi.update_attributes(workflow_params(@wf))

        if params[:commit] == 'Close'

          @wf.wi.proceed
          redirect_to action: :edit, id: @wf.wfid# TODO, :notice  => "Successfully updated and proceeded #{wi.instance.class.name.humanize}."
        else

          render action: :edit# TODO, :notice  => "Successfully updated #{wi.instance.class.name.humanize}."
        end
      else

        render action: :edit# TODO, :notice  => "Failed ..."
      end
    end

    protected

    def workflow_params(wf)

      attrs = wf.wi.attributes.keys - RuoteTrail::ActiveRecord::Base::ATTRIBUTES_TO_EXCLUDE
      params.require("#{wf.wi.module_name}_#{wf.wi.name}".underscore.to_sym).permit(attrs)
    end
  end
end