# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper_method :tasks, :last_time_entry, :assignee_accepted, :assignees, :current_assignee

      def index
        @form = form(AttachmentForm).instance
      end

      private

      def tasks
        Task.where(component: current_component)
      end

      def last_time_entry(assignee)
        time_entry = Decidim::TimeTracker::TimeEntry.where(assignee: assignee).last
        return time_entry if !time_entry.nil? && time_entry.time_end.nil?
      end

      def assignees
        Assignee.joins(:activity).where("decidim_time_tracker_activities.task_id": tasks.select(:id))
      end

      def current_assignee(activity)
        Assignee.find_by(activity: activity, user: current_user)
      end
    end
  end
end
