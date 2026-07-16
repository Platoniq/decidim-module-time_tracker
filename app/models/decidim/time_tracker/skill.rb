# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A Skill is an admin-defined competence that participants earn by
    # completing tasks. Skills belong to the organization so they can be
    # shared by every time tracker component.
    class Skill < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_skills

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      has_many :task_skills,
               class_name: "Decidim::TimeTracker::TaskSkill",
               foreign_key: "decidim_time_tracker_skill_id",
               inverse_of: :skill,
               dependent: :destroy

      has_many :tasks,
               through: :task_skills,
               class_name: "Decidim::TimeTracker::Task"

      validates :name, presence: true
      validates :required_completions_per_activity, numericality: { only_integer: true, greater_than: 0 }
    end
  end
end
