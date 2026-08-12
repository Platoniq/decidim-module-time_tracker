# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update task from Decidim's admin panel.
      class TaskForm < Decidim::Form
        include TranslatableAttributes
        include TranslationsHelper

        mimic :task

        translatable_attribute :name, String
        attribute :progress, Decimal
        attribute :skill_ids, [Integer]

        validates :name, translatable_presence: true

        def map_model(model)
          self.skill_ids = model.skill_ids
        end

        def time_tracker
          @time_tracker ||= Decidim::TimeTracker::TimeTracker.find_by(component: current_component)
        end

        def available_skills
          @available_skills ||= Skill.where(organization: current_organization).order(:id)
        end

        def skills
          available_skills.where(id: skill_ids)
        end
      end
    end
  end
end
