# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Task in the Decidim::TimeTracker component.
    class Task < ApplicationRecord
      include Decidim::HasComponent

      component_manifest_name "time_tracker"

      self.table_name = :decidim_time_tracker_tasks

      has_many :activities,
               class_name: "Decidim::TimeTracker::Activity",
               dependent: :destroy
      
      def starts_at
        activities.order(start_date: :asc).first&.start_date
      end
      
      def ends_at
        activities.order(end_date: :desc).first&.end_date
      end

      def assignees_count(filter: :accepted)
        assignees = Assignee.where(activity: activities)
        assignees = assignees.send(filter) if [:pending, :accepted, :rejected].include? filter
        assignees.count
      end
    end
  end
end
