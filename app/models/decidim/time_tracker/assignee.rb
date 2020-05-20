# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for an assigne in the Decidim::TimeTracker component.
    class Assignee < ApplicationRecord
      self.table_name = :decidim_time_tracker_assignees

      belongs_to :activity,
                 class_name: "Decidim::TimeTracker::Activity"

      has_many :time_entries,
               class_name: "Decidim::TimeTracker::TimeEntry"

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      belongs_to :invited_by_user,
                 class_name: "Decidim::User",
                 optional: true

      # Public: Checks if the assignee is verified.
      def accepted?
        status == "accepted"
      end

      # Public: Checks if the assignee is rejected.
      def rejected?
        status == "rejected"
      end

      # Public: Checks if the assignee is pending.
      def pending?
        status == "pending"
      end

      def time_dedicated?
        time_entries.sum(&:elapsed_time)
      end
    end
  end
end
