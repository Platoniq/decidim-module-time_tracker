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

      delegate :questionnaire, to: :time_tracker

      def starts_at
        activities.order(start_date: :asc).first&.start_date
      end

      def ends_at
        activities.order(end_date: :desc).first&.end_date
      end

      def assignations_count(filter: :accepted)
        assignations = Assignation.where(activity: activities).send(filter)
        assignations.count
      end

      def user_is_assignation?(user, filter: :accepted)
        Assignation.where(user: user, activity: activities).send(filter).any?
      end
    end
  end
end
