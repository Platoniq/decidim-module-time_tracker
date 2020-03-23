# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Task in the Decidim::TimeTracker component.
    class Task < ApplicationRecord
      self.table_name = :decidim_time_tracker_tasks

      belongs_to :time_tracker,
                 class_name: "Decidim::TimeTracker::TimeTracker"

      has_many :activities,
               class_name: "Decidim::TimeTracker::Activity",
               dependent: :destroy

    end
  end
end
