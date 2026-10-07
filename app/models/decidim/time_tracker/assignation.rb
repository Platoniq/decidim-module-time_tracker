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

      has_many :completions,
               class_name: "Decidim::TimeTracker::ActivityCompletion",
               foreign_key: "decidim_time_tracker_assignation_id",
               dependent: :destroy

      enum :status, { pending: 0, accepted: 1, rejected: 2 }

      # An assignation counts as completed once it has at least one verified
      # completion; completed_at mirrors the first verification.
      scope :completed, -> { where.not(completed_at: nil) }

      def assignee
        Assignee.for(user)
      end

      def completed?
        completed_at.present?
      end

      def verified_completions_count
        completions.verified.count
      end

      def pending_completions
        completions.pending
      end

      # Keeps completed_at (used by scopes and legacy UI) in sync with the
      # verified completion records.
      def sync_completed_at!
        update!(completed_at: completions.verified.minimum(:verified_at))
      end

      def time_dedicated
        time_events.sum(&:total_seconds)
      end

      def time_dedicated_to(activity)
        time_events.where(activity:).sum(&:total_seconds)
      end

      def can_change_status?
        time_events.empty?
      end

      def self.sorted_by_status(*statuses)
        collections = {
          "accepted" => accepted.sort_by(&:time_dedicated).reverse,
          "pending" => pending.to_a,
          "rejected" => rejected.to_a
        }

        statuses.flat_map { |status| collections[status.to_s] }.compact
      end

      def self.log_presenter_class_for(_log)
        Decidim::TimeTracker::AdminLog::AssignationPresenter
      end

      def self.ransackable_attributes(_auth_object = nil)
        %w(id status)
      end

      def self.ransackable_associations(_auth_object = nil)
        %w(user activity task)
      end
    end
  end
end
