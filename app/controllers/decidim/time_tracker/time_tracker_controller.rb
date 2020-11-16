# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper_method :tasks, :assignee_milestones, :start_endpoint, :stop_endpoint, :requests_path, :questionnaire_path

      def index
        @form = form(MilestoneForm).from_params(
          attachment: form(AttachmentForm).instance
        )
      end

      private

      def time_tracker
        @time_tracker ||= TimeTracker.find_by(component: current_component)
      end

      def tasks
        time_tracker.tasks
      end

      def assignee_milestones(activity)
        Milestone.where(activity: activity).order(created_at: :desc).select("DISTINCT ON (decidim_user_id, created_at) *")
      end

      def start_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_start_path(activity.task, activity.id)
      end

      def stop_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_stop_path(activity.task, activity.id)
      end

      def requests_path(activity)
        Decidim::EngineRouter.main_proxy(current_component).assignees_path(activity_id: activity.id)
      end

      def questionnaire_path(activity)
        Decidim::EngineRouter.main_proxy(current_component).new_assignee_path(task_id: activity.task, activity_id: activity.id, id: activity.questionnaire.id)
      end
    end
  end
end
