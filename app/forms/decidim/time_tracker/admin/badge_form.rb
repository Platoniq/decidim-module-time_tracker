# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update badges from Decidim's admin panel.
      class BadgeForm < Decidim::Form
        include TranslatableAttributes

        include TaskSelectable

        mimic :badge

        translatable_attribute :name, String
        translatable_attribute :description, String

        attribute :metric, String
        # Comma-separated list of level thresholds, e.g. "1, 5, 15, 30".
        attribute :levels_list, String
        attribute :skill_ids, [Integer]
        attribute :active, Boolean, default: true
        attribute :weight, Integer, default: 0

        validates :name, translatable_presence: true
        validates :metric, inclusion: { in: Decidim::TimeTracker::Badge::METRICS }
        validates :levels_list, presence: true
        validate :levels_list_is_ascending_positive_integers
        validates :skill_ids, presence: true, if: ->(form) { form.metric == "required_skills" }

        def map_model(model)
          self.levels_list = model.levels.join(", ")
          self.task_ids = model.task_ids
          self.skill_ids = model.skill_ids
        end

        def levels
          @levels ||= levels_list.to_s.split(",").map { |level| Integer(level.strip, exception: false) }
        end

        def available_skills
          @available_skills ||= Skill.where(organization: current_organization).order(:id)
        end

        def skills
          available_skills.where(id: skill_ids)
        end

        private

        def levels_list_is_ascending_positive_integers
          return if levels_list.blank?
          return errors.add(:levels_list, :invalid) if levels.any?(&:nil?)

          errors.add(:levels_list, :invalid) unless levels.all?(&:positive?) && levels == levels.sort && levels == levels.uniq
        end
      end
    end
  end
end
