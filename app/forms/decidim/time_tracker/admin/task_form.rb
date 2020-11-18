# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update task from Decidim's admin panel.
      class TaskForm < Decidim::Form
        include TranslatableAttributes

        mimic :task

        translatable_attribute :name, String

        validates :name, translatable_presence: true

        def time_tracker
          @time_tracker ||= Decidim::TimeTracker::TimeTracker.find_by(component: current_component)
        end
      end
    end
  end
end
