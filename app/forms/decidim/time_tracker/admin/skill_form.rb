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

        attribute :required_completions_per_activity, Integer, default: 1

        validates :name, translatable_presence: true
        validates :required_completions_per_activity, numericality: { only_integer: true, greater_than: 0 }

        def map_model(model)
          self.task_ids = model.task_ids
        end
      end
    end
  end
end
