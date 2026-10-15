# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Join record marking a Skill as required by a Badge (used by the
    # required_skills badge rule).
    class BadgeSkill < ApplicationRecord
      self.table_name = :decidim_time_tracker_badge_skills

      belongs_to :badge,
                 foreign_key: "decidim_time_tracker_badge_id",
                 class_name: "Decidim::TimeTracker::Badge",
                 inverse_of: :badge_skills

      belongs_to :skill,
                 foreign_key: "decidim_time_tracker_skill_id",
                 class_name: "Decidim::TimeTracker::Skill",
                 inverse_of: :badge_skills
    end
  end
end
