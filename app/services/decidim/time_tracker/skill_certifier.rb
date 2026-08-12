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
        if applicable_skills.any?
          applicable_skills.each { |skill| reconcile(skill) }
        else
          reconcile(nil)
        end

        revoke_stale_certifications
      end

      private

      attr_reader :user, :task

      # Reloaded rather than read from the association cache: callers hand us a
      # task whose skills they have just changed (UpdateTask) or whose rules
      # were edited after the object was loaded, and a stale cache would have
      # us reconcile against the previous configuration.
      def applicable_skills
        @applicable_skills ||= task.skills.reload.to_a
      end

      def reconcile(skill)
        earned = if skill
                   skill.earned_by?(user, task)
                 else
                   task.completed_by?(user)
                 end
        certification = SkillCertification.find_by(user:, task:, skill:)

        if earned && certification.nil?
          award!(skill)
        elsif !earned && certification
          revoke!(certification)
        end
      end

      # Certifications the task can no longer grant: skills that have been
      # detached from it, and the task's own fallback certification once it
      # has explicit skills. Without this they would survive forever, since
      # `reconcile` only ever visits the skills currently attached.
      def revoke_stale_certifications
        valid_skill_ids = applicable_skills.map(&:id)

        SkillCertification.where(user:, task:).find_each do |certification|
          skill_id = certification.decidim_time_tracker_skill_id
          still_granted = applicable_skills.any? ? valid_skill_ids.include?(skill_id) : skill_id.nil?

          revoke!(certification) unless still_granted
        end
      end

      # The `:time_tracker_skills` gamification score is kept in sync by
      # SkillCertification's own callbacks, so award/revoke only touch the
      # certification itself.
      def award!(skill)
        SkillCertification.create!(user:, task:, skill:, earned_at: Time.current)
        notify_user
      end

      def revoke!(certification)
        certification.destroy!
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
