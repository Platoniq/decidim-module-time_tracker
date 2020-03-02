# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for an assigne in the Decidim::TimeTracker component.
    class Assignee < ApplicationRecord
      self.table_name = :decidim_time_tracker_assignees

      belongs_to :activity,
                 foreign_key: 'decidim_time_trackers_activity_id',
                 class_name: 'Decidim::TimeTracker::Activity'

      has_many :time_entries,
               foreign_key: 'decidim_time_trackers_assignee_id',
               class_name: 'Decidim::TimeTracker::TimeEntry'
    end
  end
end
