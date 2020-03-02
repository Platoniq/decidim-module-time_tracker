# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Milestone in the Decidim::TimeTracker component.
    class Milestone < ApplicationRecord
      self.table_name = :decidim_time_tracker_milestones

      belongs_to :time_tracker,
                 foreign_key: 'decidim_time_tracker_milestone_id',
                 class_name: 'Decidim::TimeTracker::TimeTracker'
    end
  end
end
