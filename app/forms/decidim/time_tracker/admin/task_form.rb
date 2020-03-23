# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update task from Decidim's admin panel.
      class TaskForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :name, String

        validates :name, translatable_presence: true

      end
    end
  end
end
