# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Join record assigning a Skill to a Task.
    class TaskSkill < ApplicationRecord
      self.table_name = :decidim_time_tracker_task_skills

      belongs_to :task,
                 foreign_key: "decidim_time_tracker_task_id",
                 class_name: "Decidim::TimeTracker::Task"

      belongs_to :skill,
                 foreign_key: "decidim_time_tracker_skill_id",
                 class_name: "Decidim::TimeTracker::Skill"
    end
  end
end
