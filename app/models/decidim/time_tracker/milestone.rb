# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Milestone in the Decidim::TimeTracker component.
    class Milestone < ApplicationRecord
      include Decidim::HasComponent
      include Decidim::HasAttachments

      component_manifest_name "time_tracker"

      self.table_name = :decidim_time_tracker_milestones

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"
    end
  end
end
