# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Activity in the Decidim::TimeTracker component. It
    # stores a description and other useful information related to an activity.
    class Activity < ApplicationRecord
      self.table_name = :decidim_time_tracker_activities

      belongs_to :task,
                 class_name: "Decidim::TimeTracker::Task"

      has_many :assignees,
               class_name: "Decidim::TimeTracker::Assignee"

      has_many :time_entries,
               class_name: "Decidim::TimeTracker::TimeEntry"

      def dedicated_time
        time_entries.where.not(elapsed_time: [nil]).sum(&:elapsed_time)
      end
    end
  end
end
