# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Task in the Decidim::TimeTracker component.
    class Task < ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Forms::HasQuestionnaire

      component_manifest_name "time_tracker"

      self.table_name = :decidim_time_tracker_tasks

      has_many :activities,
               class_name: "Decidim::TimeTracker::Activity",
               dependent: :destroy
    end
  end
end
