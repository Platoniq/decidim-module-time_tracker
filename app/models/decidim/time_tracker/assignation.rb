# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for an assignation in the Decidim::TimeTracker component.
    class Assignation < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_assignations

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      belongs_to :invited_by_user,
                 class_name: "Decidim::User",
                 optional: true

      belongs_to :activity,
                 class_name: "Decidim::TimeTracker::Activity"

      has_one :task,
              class_name: "Decidim::TimeTracker::Task",
              through: :activity

      has_many :time_events,
               class_name: "Decidim::TimeTracker::TimeEvent",
               dependent: :nullify

      has_many :milestones,
               class_name: "Decidim::TimeTracker::Milestone",
               through: :user

      enum status: [:pending, :accepted, :rejected]

      def assignee
        Assignee.for(user)
      end

      def time_dedicated
        time_events.sum(&:total_seconds)
      end

      def time_dedicated_to(activity)
        time_events.where(activity: activity).sum(&:total_seconds)
      end

      def can_change_status?
        time_events.empty?
      end

      # rubocop:disable Lint/UselessAssignment
      def self.sorted_by_status(*statuses)
        accepted = self.accepted.sort_by(&:time_dedicated).reverse
        pending = self.pending
        rejected = self.rejected

        statuses.map { |status| send(status) }.sum
      end
      # rubocop:enable Lint/UselessAssignment

      def self.log_presenter_class_for(_log)
        Decidim::TimeTracker::AdminLog::AssignationPresenter
      end
    end
  end
end
