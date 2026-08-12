# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A Skill is an admin-defined competence that participants earn by
    # working on tasks. Skills belong to the organization so they can be
    # shared by every time tracker component.
    #
    # How a skill is earned depends on its earning mode:
    # - completed_activities: a number of the task's activities (or all of
    #   them) each with enough admin-verified completions.
    # - time_spent: a total amount of tracked time across the task's
    #   activities.
    class Skill < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_skills

      EARNING_MODES = %w(completed_activities time_spent).freeze

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      has_many :task_skills,
               class_name: "Decidim::TimeTracker::TaskSkill",
               foreign_key: "decidim_time_tracker_skill_id",
               inverse_of: :skill,
               dependent: :destroy

      has_many :tasks,
               through: :task_skills,
               class_name: "Decidim::TimeTracker::Task"

      has_many :badge_skills,
               class_name: "Decidim::TimeTracker::BadgeSkill",
               foreign_key: "decidim_time_tracker_skill_id",
               inverse_of: :skill,
               dependent: :destroy

      # Certifications reference the skill with a foreign key, so deleting a
      # skill that anyone has already earned would raise unless they are
      # destroyed with it (which also unwinds the gamification score).
      has_many :skill_certifications,
               class_name: "Decidim::TimeTracker::SkillCertification",
               foreign_key: "decidim_time_tracker_skill_id",
               inverse_of: :skill,
               dependent: :destroy

      validates :name, presence: true
      validates :earning_mode, inclusion: { in: EARNING_MODES }
      validates :required_completions_per_activity, numericality: { only_integer: true, greater_than: 0 }
      validates :required_activities_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
      validates :required_minutes, numericality: { only_integer: true, greater_than: 0 }, if: :time_spent?

      def time_spent?
        earning_mode == "time_spent"
      end

      # Whether the user's work on the given task satisfies this skill's
      # earning rule.
      def earned_by?(user, task)
        if time_spent?
          time_spent_by(user, task) >= required_minutes.to_i * 60
        else
          enough_activities_completed_by?(user, task)
        end
      end

      private

      def time_spent_by(user, task)
        TimeEvent.where(user:, activity: task.activities).sum(:total_seconds)
      end

      def enough_activities_completed_by?(user, task)
        active_activities = task.activities.active
        return false if active_activities.empty?

        verified_counts = ActivityCompletion.verified
                                            .joins(:assignation)
                                            .where(decidim_time_tracker_assignations: { decidim_user_id: user.id, activity_id: active_activities.ids })
                                            .group("decidim_time_tracker_assignations.activity_id")
                                            .count

        completed = active_activities.ids.count { |activity_id| verified_counts.fetch(activity_id, 0) >= required_completions_per_activity }
        completed >= (required_activities_count || active_activities.size)
      end
    end
  end
end
