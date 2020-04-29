# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      helper_method :tasks, :last_time_entry

      private

      def tasks
        Task.where(component: current_component)
      end

      def last_time_entry(assignee)
        time_entry = Decidim::TimeTracker::TimeEntry.where(assignee: assignee).last
        return time_entry if !time_entry.nil? && time_entry.time_end.nil?
      end
    end
  end
end
