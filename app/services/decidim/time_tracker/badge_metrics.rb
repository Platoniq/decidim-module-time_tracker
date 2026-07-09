# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Computes the value of each badge metric for a user. Metrics are
    # organization-wide: they aggregate over every time tracker component.
    class BadgeMetrics
      def initialize(user)
        @user = user
      end

      def value_for(metric)
        raise ArgumentError, "Unknown metric: #{metric}" unless Badge::METRICS.include?(metric.to_s)

        send(metric)
      end

      private

      attr_reader :user

      def completed_activities
        @completed_activities ||= Assignation.completed.where(user:).count
      end

      # Counts distinct explicit skills across the user's certified tasks;
      # tasks without explicit skills count as one skill each (the task name
      # acts as the skill, mirroring SkillCertification#skill_names).
      def skills_earned
        @skills_earned ||= begin
          certified_task_ids = SkillCertification.where(user:).select(:decidim_time_tracker_task_id)
          task_skills = TaskSkill.where(decidim_time_tracker_task_id: certified_task_ids)
          explicit_skills = task_skills.distinct.count(:decidim_time_tracker_skill_id)
          tasks_with_skills = task_skills.distinct.count(:decidim_time_tracker_task_id)
          explicit_skills + (SkillCertification.where(user:).count - tasks_with_skills)
        end
      end

      def time_dedicated_hours
        @time_dedicated_hours ||= TimeEvent.where(user:).sum(:total_seconds) / 3600
      end

      def milestones_created
        @milestones_created ||= Milestone.where(user:).count
      end
    end
  end
end
