# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneesController < ApplicationController
      def new
        # enforce_permission_to :create, :assignee

        CreateRequestAssignee.call(current_activity, current_user) do
          on(:ok) do
            # flash[:notice] = I18n.t("assignees.request.success", scope: "decidim.time_tracer")
            redirect_to EngineRouter.main_proxy(current_component).root_path
          end

          on(:invalid) do
            # flash[:notice] = I18n.t("assignees.request.success", scope: "decidim.time_tracer")
            redirect_to EngineRouter.main_proxy(current_component).root_path
          end
        end
      end

      private

      def current_task
        @task = Task.find(params[:task_id])
      end

      def current_activity
        @activity = Activity.find(params[:activity_id])
      end
    end
  end
end
