# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeQuestionnaire < ApplicationRecord
      include Decidim::Forms::HasQuestionnaire

      self.table_name = :decidim_time_tracker_assignee_questionnaires

      belongs_to :time_tracker,
                 class_name: "Decidim::TimeTracker::TimeTracker",
                 inverse_of: :assignee_questionnaire

      after_create :create_questionnaire

      def has_questions?
        questionnaire.questions.any?
      end

      private

      def create_questionnaire
        Decidim::Forms::Questionnaire.create!(questionnaire_for: self) if questionnaire.blank?
      end
    end
  end
end
