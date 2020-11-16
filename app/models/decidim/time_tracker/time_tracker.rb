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
              class_name: "Decidim::TimeTracker::AssigneeQuestionnaire",
              inverse_of: :time_tracker

      after_create :create_questionnaire, :create_assignee_questionnaire

      def has_questions?
        questionnaire.questions.any?
      end

      private

      def create_questionnaire
        questionnaire ||= Decidim::Forms::Questionnaire.create!(questionnaire_for: self)
      end

      def create_assignee_questionnaire
        assignee_questionnaire ||= Decidim::TimeTracker::AssigneeQuestionnaire.create!(time_tracker: self)
      end
    end
  end
end
