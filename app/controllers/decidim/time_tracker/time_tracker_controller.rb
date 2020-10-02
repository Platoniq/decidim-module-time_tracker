# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper_method :tasks, :assignee_accepted, :assignees, :start_endpoint, :stop_endpoint, :request_path, :milestones_path

      def index
        @form = form(MilestoneForm).from_params(
          attachment: form(AttachmentForm).instance
        )
      end

      private

      def tasks
        Task.where(component: current_component)
      end

      def assignees
        Assignee.joins(:activity).where("decidim_time_tracker_activities.task_id": tasks.select(:id))
      end

      def start_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_start_path(activity.task, activity.id)
      end

      def stop_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_stop_path(activity.task, activity.id)
      end

      def request_path(activity)
        Decidim::EngineRouter.main_proxy(current_component).new_task_activity_assignee_path(activity.task, activity.id)
      end

      def milestones_path
        Decidim::EngineRouter.main_proxy(current_component).milestones_path
      end
    end
  end
end
