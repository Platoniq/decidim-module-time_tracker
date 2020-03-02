# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Activity in the Decidim::TimeTracker component. It
    # stores a description and other useful information related to an activity.
    class Activity < ApplicationRecord
      self.table_name = :decidim_time_tracker_activities

      belongs_to :task,
                 foreign_key: 'decidim_time_trackers_task_id',
                 class_name: 'Decidim::TimeTracker::Task'

      has_many :assignees,
               foreign_key: 'decidim_time_trackers_activity_id',
               class_name: 'Decidim::TimeTracker::Assignees'

      has_many :time_entries,
               foreign_key: 'decidim_time_trackers_activity_id',
               class_name: 'Decidim::TimeTracker::TimeEntry'
    end
  end
end
