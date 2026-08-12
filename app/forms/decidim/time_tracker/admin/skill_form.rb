# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update skills from Decidim's admin panel.
      class SkillForm < Decidim::Form
        include TranslatableAttributes
        include TaskSelectable

        mimic :skill

        translatable_attribute :name, String
        translatable_attribute :description, String

        attribute :earning_mode, String, default: "completed_activities"
        attribute :required_completions_per_activity, Integer, default: 1
        # nil/blank means every active activity of the task is required.
        attribute :required_activities_count, Integer
        attribute :required_hours, Decimal

        validates :name, translatable_presence: true
        validates :earning_mode, inclusion: { in: Decidim::TimeTracker::Skill::EARNING_MODES }
        validates :required_completions_per_activity, numericality: { only_integer: true, greater_than: 0 }
        validates :required_activities_count, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
        validates :required_hours, numericality: { greater_than: 0 }, if: ->(form) { form.earning_mode == "time_spent" }

        def map_model(model)
          self.task_ids = model.task_ids
          self.required_hours = (model.required_minutes / 60.0).round(2) if model.required_minutes.present?
        end

        def required_minutes
          return nil if required_hours.blank?

          (required_hours * 60).round
        end
      end
    end
  end
end
