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
      # in Decidim::TimeTracker::BadgeMetrics. The required_skills metric
      # counts how many of the badge's own required skills are certified.
      METRICS = %w(completed_activities skills_earned required_skills time_dedicated_hours milestones_created).freeze

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      has_many :badge_tasks,
               class_name: "Decidim::TimeTracker::BadgeTask",
               foreign_key: "decidim_time_tracker_badge_id",
               inverse_of: :badge,
               dependent: :destroy

      # The tasks this badge's rule is restricted to; empty means the rule
      # counts progress over every task.
      has_many :tasks,
               through: :badge_tasks,
               class_name: "Decidim::TimeTracker::Task"

      has_many :badge_skills,
               class_name: "Decidim::TimeTracker::BadgeSkill",
               foreign_key: "decidim_time_tracker_badge_id",
               inverse_of: :badge,
               dependent: :destroy

      # The skills required by the required_skills rule.
      has_many :skills,
               through: :badge_skills,
               class_name: "Decidim::TimeTracker::Skill"

      scope :active, -> { where(active: true) }
      scope :sorted, -> { order(weight: :asc, id: :asc) }

      validates :name, presence: true
      validates :metric, inclusion: { in: METRICS }
      validates :levels, presence: true
      validate :levels_are_sorted_positive_integers
      validate :skills_selected_for_required_skills

      def required_skills?
        metric == "required_skills"
      end

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

      def skills_selected_for_required_skills
        errors.add(:metric, :skills_missing) if required_skills? && badge_skills.empty? && skills.empty?
      end
    end
  end
end
