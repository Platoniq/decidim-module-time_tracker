# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper_method :tasks, :last_time_event, :assignee_accepted, :assignees, :current_assignee, :start_endpoint, :stop_endpoint

      def index
        @form = form(AttachmentForm).instance
      end

      private

      def tasks
        Task.where(component: current_component)
      end

      def last_time_event(assignee)
        time_event = TimeEvent.last_for(assignee)
        return unless time_event
        return time_event if time_event.stop.blank?
      end

      def assignees
        Assignee.joins(:activity).where("decidim_time_tracker_activities.task_id": tasks.select(:id))
      end

      def current_assignee(activity)
        Assignee.find_by(activity: activity, user: current_user)
      end

      def start_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_start_path(activity.task, activity.id)
      end

      def stop_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_stop_path(activity.task, activity.id)
      end
    end
  end
end
