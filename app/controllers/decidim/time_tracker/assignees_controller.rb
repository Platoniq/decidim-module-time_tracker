# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneesController < Decidim::TimeTracker::ApplicationController
      helper_method :assignee, :milestones

      def new
        # enforce_permission_to :create, :assignee

        CreateRequestAssignee.call(current_activity, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("assignees.request.success", scope: "decidim.time_tracker")
            redirect_to EngineRouter.main_proxy(current_task.component).root_path
          end

          on(:invalid) do
            flash[:notice] = I18n.t("assignees.request.error", scope: "decidim.time_tracker")
            redirect_to EngineRouter.main_proxy(current_task.component).root_path
          end
        end
      end

      def show; end

      private

      def current_task
        @task = Task.find(params[:task_id])
      end

      def current_activity
        @activity = Activity.find(params[:activity_id])
      end

      def assignee
        @assignee = Assignee.find(params[:id])
      end

      def milestones
        @milestones = Milestone.where(id: assignee.time_entries.select(:id))
      end
    end
  end
end
