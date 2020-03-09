# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Milestone in the Decidim::TimeTracker component.
    class Milestone < ApplicationRecord
      include Decidim::HasAttachments

      self.table_name = :decidim_time_tracker_milestones

      belongs_to :time_tracker,
                 class_name: "Decidim::TimeTracker::TimeTracker"

      has_many :time_entries,
               class_name: "Decidim::TimeTracker::TimeEntry"

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"
    end
  end
end
