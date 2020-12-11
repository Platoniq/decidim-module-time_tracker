# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a AssigneeData in the Decidim::TimeTracker component.
    class AssigneeData < ApplicationRecord
      include Decidim::Forms::HasQuestionnaire

      self.table_name = :decidim_time_tracker_assignee_data

      belongs_to :time_tracker,
                 class_name: "Decidim::TimeTracker::TimeTracker"

      delegate :questions, :answers, to: :questionnaire

      delegate :organization, to: :time_tracker
    end
  end
end
