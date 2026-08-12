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

      # Admins choose how many levels a badge has; the thresholds for each one
      # are prefilled from these curves so a badge can be set up without
      # thinking about numbers at all. They stay editable afterwards.
      MAX_LEVELS = 10

      DEFAULT_LEVEL_CURVES = {
        "completed_activities" => [1, 3, 5, 10, 15, 20, 30, 40, 50, 75],
        "skills_earned" => [1, 2, 3, 5, 8, 10, 12, 15, 20, 25],
        # One level per required skill: any more would be unreachable.
        "required_skills" => (1..MAX_LEVELS).to_a,
        "time_dedicated_hours" => [1, 5, 10, 25, 50, 75, 100, 150, 200, 300],
        "milestones_created" => [1, 3, 5, 10, 15, 20, 30, 40, 50, 75]
      }.freeze

      DEFAULT_LEVEL_COUNT = 3

      # Admin-defined badges carry no image of their own, so the emblem is
      # derived from what the badge counts. Lives here rather than in a helper
      # because both the public explainer and the component's task list need
      # it, and they load different helper sets.
      METRIC_ICONS = {
        "completed_activities" => "trophy-line",
        "skills_earned" => "award-line",
        "required_skills" => "medal-line",
        "time_dedicated_hours" => "timer-line",
        "milestones_created" => "quill-pen-line"
      }.freeze

      # The suggested thresholds for a metric at a given number of levels.
      def self.default_levels(metric, count)
        curve = DEFAULT_LEVEL_CURVES.fetch(metric.to_s, DEFAULT_LEVEL_CURVES["completed_activities"])
        curve.first(count.to_i.clamp(1, MAX_LEVELS))
      end

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
      validate :levels_are_reachable

      def icon_name
        METRIC_ICONS.fetch(metric, "trophy-line")
      end

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

      # A required_skills badge counts certified skills, so a threshold above
      # the number of skills it names can never be met — the level would sit
      # there permanently out of reach.
      def levels_are_reachable
        return unless required_skills?
        return if levels.blank?

        available = [badge_skills.size, skills.size].max
        return if available.zero? || levels.max <= available

        errors.add(:levels, :unreachable, count: available)
      end
    end
  end
end
