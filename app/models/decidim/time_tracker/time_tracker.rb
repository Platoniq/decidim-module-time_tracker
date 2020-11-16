# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTracker < ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Forms::HasQuestionnaire

      self.table_name = :decidim_time_trackers
      
      component_manifest_name "time_tracker"

      has_many :tasks,
               class_name: "Decidim::TimeTracker::Task",
               dependent: :destroy
      
      has_many :activities,
               class_name: "Decidim::TimeTracker::Activity",
               through: :tasks
      
      has_many :assignees,
               class_name: "Decidim::TimeTracker::Assignee",
               through: :activities

      has_one :assignee_questionnaire,
                class_name: "Decidim::Forms::Questionnaire",
                dependent: :destroy,
                inverse_of: :questionnaire_for,
                as: :questionnaire_for

      after_create :create_questionnaires

      def has_questions?
        questionnaire.questions.any?
      end

      private

      def create_questionnaires
        questionnaire ||= Decidim::Forms::Questionnaire.create!(questionnaire_for: self)
        assignee_questionnaire ||= Decidim::Forms::Questionnaire.create!(questionnaire_for: self)
      end
    end
  end
end
