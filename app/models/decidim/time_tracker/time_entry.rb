# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a time entry in the Decidim::TimeTracker component.
    class TimeEntry < ApplicationRecord
      self.table_name = :decidim_time_tracker_time_entries

      belongs_to :assignee,
                 class_name: "Decidim::TimeTracker::Assignee"

      belongs_to :milestone,
                 class_name: "Decidim::TimeTracker::Milestone"

      belongs_to :activity,
                 class_name: "Decidim::TimeTracker::Activity"

      belongs_to :validated_by_user,
                 class_name: "Decidim::User"
    end
  end
end
