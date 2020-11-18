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

      def assignees_count(filter: :accepted)
        assignees = Assignee.where(activity: activities).send(filter)
        assignees.count
      end

      def user_is_assignee?(user, filter: :accepted)
        Assignee.where(user: user, activity: activities).send(filter).any?
      end
    end
  end
end
