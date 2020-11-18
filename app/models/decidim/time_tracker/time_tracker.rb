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

      has_many :assignations,
               class_name: "Decidim::TimeTracker::Assignation",
               through: :activities

      after_create :populate_questionnaire

      def has_questions?
        questionnaire.questions.any?
      end

      private

      def populate_questionnaire
        return if questionnaire.blank?
        return unless Rails.application.config.respond_to?(:time_tracker_questionnaire_seeds)

        @questionnaire_seeds ||= Rails.application.config.time_tracker_questionnaire_seeds

        return if @questionnaire_seeds.blank?

        if @questionnaire_seeds[:questions]&.first.is_a?(Hash)
          questions = @questionnaire_seeds[:questions].map do |question|
            if question.has_key?(:answer_options)
              answer_options = question.delete(:answer_options)
              answer_options.map! { |answer_option| Decidim::Forms::AnswerOption.new(answer_option) }
              question[:answer_options] = answer_options
            end

            Decidim::Forms::Question.create(question.merge(questionnaire: questionnaire))
          end

          @questionnaire_seeds[:questions] = questions
        end

        questionnaire.update!(@questionnaire_seeds)
      end
    end
  end
end
