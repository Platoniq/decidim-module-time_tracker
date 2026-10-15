# frozen_string_literal: true

module Decidim
  module TimeTracker
    # One completed "round" of an activity by a user. Created automatically
    # (pending) when the user's tracked time meets the activity's completion
    # criteria, or manually by an admin. Only completions verified by an
    # admin count towards badges and skills.
    class ActivityCompletion < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_activity_completions

      belongs_to :assignation,
                 foreign_key: "decidim_time_tracker_assignation_id",
                 class_name: "Decidim::TimeTracker::Assignation"

      belongs_to :verified_by,
                 class_name: "Decidim::User",
                 optional: true

      has_one :activity, through: :assignation
      has_one :task, through: :assignation

      delegate :user, to: :assignation

      scope :verified, -> { where.not(verified_at: nil) }
      scope :pending, -> { where(verified_at: nil) }

      validates :requested_at, presence: true

      def verified?
        verified_at.present?
      end
    end
  end
end
