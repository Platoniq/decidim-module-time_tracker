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

        validates :name, translatable_presence: true

        def map_model(model)
          self.task_ids = model.task_ids
        end
      end
    end
  end
end
