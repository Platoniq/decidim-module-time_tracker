# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Awards or revokes a user's skill certifications for a given task,
    # keeping the `:time_tracker_skills` gamification badge in sync. Safe to
    # call repeatedly: it only acts when a certification's state actually
    # needs to change.
    #
    # A task with explicit skills certifies each skill independently, using
    # the skill's required completions per activity; a task without skills
    # certifies the task itself (one verified completion per activity).
    class SkillCertifier
      def initialize(user, task)
        @user = user
        @task = task
      end

      # Reconciles every certification of the task with the user's current
      # verified completions.
      def refresh
        if task.skills.any?
          task.skills.each do |skill|
            reconcile(skill, skill.required_completions_per_activity)
          end
          revoke_fallback_certification
        else
          reconcile(nil, 1)
        end
      end

      private

      attr_reader :user, :task

      def reconcile(skill, required_completions)
        earned = task.completed_by?(user, required_completions:)
        certification = SkillCertification.find_by(user:, task:, skill:)

        if earned && certification.nil?
          award!(skill)
        elsif !earned && certification
          revoke!(certification)
        end
      end

      # A task that gained explicit skills later should not keep certifying
      # under its own name.
      def revoke_fallback_certification
        certification = SkillCertification.find_by(user:, task:, skill: nil)
        revoke!(certification) if certification
      end

      def award!(skill)
        SkillCertification.transaction do
          SkillCertification.create!(user:, task:, skill:, earned_at: Time.current)
          Decidim::Gamification.increment_score(user, :time_tracker_skills)
        end
        notify_user
      end

      def revoke!(certification)
        SkillCertification.transaction do
          certification.destroy!
          Decidim::Gamification.decrement_score(user, :time_tracker_skills)
        end
      end

      def notify_user
        Decidim::EventsManager.publish(
          event: "decidim.events.time_tracker.skill_certified_event",
          event_class: Decidim::TimeTracker::SkillCertifiedEvent,
          resource: task,
          affected_users: [user]
        )
      end
    end
  end
end
