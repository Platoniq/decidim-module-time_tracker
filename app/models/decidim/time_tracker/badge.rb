# frozen_string_literal: true

module Decidim
  module TimeTracker
    # An admin-defined badge. Unlike the badges registered with
    # Decidim::Gamification (which are fixed in code at boot), these are
    # stored per organization so admins can create them and tune their
    # levels and rules from the admin panel.
    class Badge < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_badges

      # The metrics a badge can be based on. Each one maps to a calculation
      # in Decidim::TimeTracker::BadgeMetrics.
      METRICS = %w(completed_activities skills_earned time_dedicated_hours milestones_created).freeze

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      has_many :badge_tasks,
               class_name: "Decidim::TimeTracker::BadgeTask",
               foreign_key: "decidim_time_tracker_badge_id",
               dependent: :destroy

      # The tasks this badge's rule is restricted to; empty means the rule
      # counts progress over every task.
      has_many :tasks,
               through: :badge_tasks,
               class_name: "Decidim::TimeTracker::Task"

      scope :active, -> { where(active: true) }
      scope :sorted, -> { order(weight: :asc, id: :asc) }

      validates :name, presence: true
      validates :metric, inclusion: { in: METRICS }
      validates :levels, presence: true
      validate :levels_are_sorted_positive_integers

      # The level (1-based) reached with the given metric value; 0 when the
      # first threshold has not been reached yet.
      def level_for(value)
        levels.count { |threshold| value >= threshold }
      end

      def max_level
        levels.count
      end

      # The threshold needed for the next level, or nil when maxed out.
      def next_level_threshold(value)
        levels.find { |threshold| value < threshold }
      end

      private

      def levels_are_sorted_positive_integers
        return if levels.blank?

        errors.add(:levels, :invalid) unless levels.all? { |level| level.is_a?(Integer) && level.positive? } && levels == levels.sort && levels == levels.uniq
      end
    end
  end
end
