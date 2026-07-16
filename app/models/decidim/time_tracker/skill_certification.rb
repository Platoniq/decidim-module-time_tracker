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
                 class_name: "Decidim::TimeTracker::Task"

      belongs_to :skill,
                 foreign_key: "decidim_time_tracker_skill_id",
                 class_name: "Decidim::TimeTracker::Skill",
                 optional: true

      validates :decidim_time_tracker_task_id, uniqueness: { scope: [:decidim_user_id, :decidim_time_tracker_skill_id] }

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
    end
  end
end
