# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeEntriesController < Decidim::TimeTracker::ApplicationController
      helper_method :activity, :task

      def new
        enforce_permission_to :create, :activities

        CreateTimeEntry.call(activity, curernt_user) do
          on(:ok) do
            # flash[:notice] = I18n.t("time_entries.create.success"), scope: "decidim.time_tracker"
            redirect_to EngineRouter.main_proxy(current_component).task_activities_path(task, activity)
          end
        end
      end

      def task
        Task.find(params[:task_id])
      end

      def activity
        Activity.find(params[:activity_id])
      end
    end
  end
end
