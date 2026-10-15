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

      def value_for(metric, task_ids: [], skill_ids: [])
        raise ArgumentError, "Unknown metric: #{metric}" unless Badge::METRICS.include?(metric.to_s)

        task_ids = Array(task_ids)
        skill_ids = Array(skill_ids)
        @values ||= {}
        @values[[metric.to_s, task_ids, skill_ids]] ||= if metric.to_s == "required_skills"
                                                          required_skills(skill_ids)
                                                        else
                                                          send(metric.to_s, task_ids)
                                                        end
      end

      private

      attr_reader :user

      # How many of the given skills the user has been certified for.
      def required_skills(skill_ids)
        return 0 if skill_ids.empty?

        SkillCertification.where(user:, decidim_time_tracker_skill_id: skill_ids)
                          .distinct
                          .count(:decidim_time_tracker_skill_id)
      end

      # Counts admin-verified completions, so completing the same activity
      # several times counts several times.
      def completed_activities(task_ids)
        scope = ActivityCompletion.verified
                                  .joins(assignation: :activity)
                                  .where(decidim_time_tracker_assignations: { decidim_user_id: user.id })
        scope = scope.where(decidim_time_tracker_activities: { task_id: task_ids }) if task_ids.any?
        scope.count
      end

      # Counts distinct explicit skills certified to the user; certifications
      # of tasks without explicit skills count as one skill each (the task
      # name acts as the skill).
      def skills_earned(task_ids)
        certifications = SkillCertification.where(user:)
        certifications = certifications.where(decidim_time_tracker_task_id: task_ids) if task_ids.any?

        explicit_skills = certifications.where.not(decidim_time_tracker_skill_id: nil).distinct.count(:decidim_time_tracker_skill_id)
        fallback_skills = certifications.where(decidim_time_tracker_skill_id: nil).count
        explicit_skills + fallback_skills
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
