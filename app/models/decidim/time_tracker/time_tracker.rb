# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a TimeTracker in the Decidim::TimeTracker component.
    class TimeTracker < ApplicationRecord
      include Decidim::HasComponent

      component_manifest_name 'time_tracker'

      self.table_name = :decidim_time_trackers

      has_many :tasks,
               foreign_key: 'decidim_time_tracker_task_id',
               class_name: 'Decidim::TimeTracker::Task'

      has_many :milestones,
               foreign_key: 'decidim_time_tracker_milestone_id',
               class_name: 'Decidim::TimeTracker::Milestone'
    end
  end
end
