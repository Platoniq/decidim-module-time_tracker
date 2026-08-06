# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A SkillCertification is awarded to a user when every active activity of
    # a Task has enough admin-verified completions. It certifies one explicit
    # Skill of the task, or — when the task has no explicit skills — the task
    # itself (skill is NULL and the task's name acts as the skill).
    class SkillCertification < ApplicationRecord
      self.table_name = :decidim_time_tracker_skill_certifications

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      belongs_to :task,
                 foreign_key: "decidim_time_tracker_task_id",
                 class_name: "Decidim::TimeTracker::Task",
                 inverse_of: :skill_certifications

      belongs_to :skill,
                 foreign_key: "decidim_time_tracker_skill_id",
                 class_name: "Decidim::TimeTracker::Skill",
                 inverse_of: :skill_certifications,
                 optional: true

      validates :decidim_time_tracker_task_id, uniqueness: { scope: [:decidim_user_id, :decidim_time_tracker_skill_id] }

      # The `:time_tracker_skills` gamification score mirrors the number of
      # certifications, so it is kept in sync here rather than in the callers:
      # certifications also disappear through `dependent: :destroy` when a task
      # or a skill is deleted, and those paths would otherwise leave the score
      # permanently inflated.
      after_create :increment_gamification_score
      after_destroy :decrement_gamification_score

      delegate :component, to: :task
      delegate :organization, to: :user

      # The name of the certified skill (the skill's name, or the task's name
      # for the NULL-skill fallback).
      def skill_name
        skill&.name || task.name
      end

      # Kept for callers that render a list; a certification now certifies a
      # single skill.
      def skill_names
        [skill_name]
      end

      private

      def increment_gamification_score
        Decidim::Gamification.increment_score(user, :time_tracker_skills)
      end

      def decrement_gamification_score
        Decidim::Gamification.decrement_score(user, :time_tracker_skills)
      end
    end
  end
end
