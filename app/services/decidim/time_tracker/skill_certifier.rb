# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Awards or revokes a user's skill certification for a given task, keeping the
    # `:time_tracker_skills` gamification badge in sync. Safe to call repeatedly:
    # it only acts when the certification state actually needs to change.
    class SkillCertifier
      def initialize(user, task)
        @user = user
        @task = task
      end

      # Reconciles the certification with the task's current completion state.
      def refresh
        if task.completed_by?(user)
          award! unless certification
        elsif certification
          revoke!
        end
      end

      private

      attr_reader :user, :task

      def certification
        @certification ||= SkillCertification.find_by(user:, task:)
      end

      def award!
        SkillCertification.transaction do
          SkillCertification.create!(user:, task:, earned_at: Time.current)
          Decidim::Gamification.increment_score(user, :time_tracker_skills)
        end
        notify_user
      end

      def revoke!
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
