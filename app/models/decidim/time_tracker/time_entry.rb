# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a time entry in the Decidim::TimeTracker component.
    class TimeEntry < ApplicationRecord
      self.table_name = :decidim_time_tracker_time_entries

      belongs_to :assignee,
                 foreign_key: 'decidim_time_trackers_assignee_id',
                 class_name: 'Decidim::TimeTracker::Assignee'

      belongs_to :milestone,
                 foreign_key: 'decidim_time_trackers_milestone_id',
                 class_name: 'Decidim::TimeTracker::Milestone'

      belongs_to :activity,
                 foreign_key: 'decidim_time_trackers_activity_id',
                 class_name: 'Decidim::TimeTracker::Activity'
    end
  end
end
