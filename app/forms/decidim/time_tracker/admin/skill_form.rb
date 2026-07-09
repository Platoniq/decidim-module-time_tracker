# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update skills from Decidim's admin panel.
      class SkillForm < Decidim::Form
        include TranslatableAttributes

        mimic :skill

        translatable_attribute :name, String
        translatable_attribute :description, String

        validates :name, translatable_presence: true
      end
    end
  end
end
