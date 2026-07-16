# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Computes the value of each badge metric for a user. Metrics aggregate
    # over every time tracker component unless a list of task ids is given,
    # in which case only progress within those tasks is counted.
    class BadgeMetrics
      def initialize(user)
        @user = user
      end

      def value_for(metric, task_ids: [])
        raise ArgumentError, "Unknown metric: #{metric}" unless Badge::METRICS.include?(metric.to_s)

        task_ids = Array(task_ids)
        @values ||= {}
        @values[[metric.to_s, task_ids]] ||= send(metric.to_s, task_ids)
      end

      private

      attr_reader :user

      def completed_activities(task_ids)
        scope = Assignation.completed.where(user:)
        scope = scope.joins(:activity).where(decidim_time_tracker_activities: { task_id: task_ids }) if task_ids.any?
        scope.count
      end

      # Counts distinct explicit skills across the user's certified tasks;
      # tasks without explicit skills count as one skill each (the task name
      # acts as the skill, mirroring SkillCertification#skill_names).
      def skills_earned(task_ids)
        certifications = SkillCertification.where(user:)
        certifications = certifications.where(decidim_time_tracker_task_id: task_ids) if task_ids.any?

        certified_task_ids = certifications.select(:decidim_time_tracker_task_id)
        task_skills = TaskSkill.where(decidim_time_tracker_task_id: certified_task_ids)
        explicit_skills = task_skills.distinct.count(:decidim_time_tracker_skill_id)
        tasks_with_skills = task_skills.distinct.count(:decidim_time_tracker_task_id)
        explicit_skills + (certifications.count - tasks_with_skills)
      end

      def time_dedicated_hours(task_ids)
        scope = TimeEvent.where(user:)
        scope = scope.joins(:activity).where(decidim_time_tracker_activities: { task_id: task_ids }) if task_ids.any?
        scope.sum(:total_seconds) / 3600
      end

      def milestones_created(task_ids)
        scope = Milestone.where(user:)
        scope = scope.joins(:activity).where(decidim_time_tracker_activities: { task_id: task_ids }) if task_ids.any?
        scope.count
      end
    end
  end
end
