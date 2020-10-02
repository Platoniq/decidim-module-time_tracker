# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Milestone in the Decidim::TimeTracker component.
    class Milestone < ApplicationRecord
      include Decidim::HasAttachments

      self.table_name = :decidim_time_tracker_milestones

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      belongs_to :activity,
                 class_name: "Decidim::TimeTracker::Activity"
    end
  end
end
