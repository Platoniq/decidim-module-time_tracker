# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A SkillCertification is awarded to a user when they complete every active
    # activity of a Task. Each Task represents a "skill", so the certification
    # certifies that the user has acquired that skill.
    class SkillCertification < ApplicationRecord
      self.table_name = :decidim_time_tracker_skill_certifications

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      belongs_to :task,
                 foreign_key: "decidim_time_tracker_task_id",
                 class_name: "Decidim::TimeTracker::Task"

      validates :decidim_time_tracker_task_id, uniqueness: { scope: :decidim_user_id }

      delegate :component, to: :task
      delegate :organization, to: :user

      # The name of the certified skill (the task's name multiloc).
      def skill_name
        task.name
      end
    end
  end
end
