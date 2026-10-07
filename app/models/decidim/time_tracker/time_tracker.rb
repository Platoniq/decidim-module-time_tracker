# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTracker < ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Forms::HasQuestionnaire
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_trackers

      component_manifest_name "time_tracker"

      has_many :tasks,
               -> { order("decidim_time_tracker_tasks.weight" => :asc, "decidim_time_tracker_tasks.id" => :asc) },
               class_name: "Decidim::TimeTracker::Task",
               dependent: :destroy

      has_many :activities,
               class_name: "Decidim::TimeTracker::Activity",
               through: :tasks

      has_many :assignations,
               class_name: "Decidim::TimeTracker::Assignation",
               through: :activities

      has_one :assignee_data, # rubocop:disable Rails/HasManyOrHasOneDependent
              class_name: "Decidim::TimeTracker::AssigneeData"

      has_one :assignee_questionnaire,
              source: :questionnaire,
              through: :assignee_data,
              class_name: "Decidim::Forms::Questionnaire"

      def has_questions?
        questionnaire.questions.any?
      end

      # Volunteers fill in the "About you" questionnaire, accepting its terms,
      # before their first join request. With no questions there is nothing to
      # fill in: the request goes straight through and stands for the terms.
      def has_assignee_questions?
        questionnaire = assignee_data&.questionnaire
        questionnaire.present? && questionnaire.questions.any?
      end

      alias activity_questionnaire questionnaire
    end
  end
end
