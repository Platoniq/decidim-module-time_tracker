# frozen_string_literal: true

module Decidim
  module TimeTracker
    # This class serializes the answers given by a User for questionnaire so can be
    # exported to CSV, JSON or other formats.
    class TimeTrackerActivityQuestionnaireAnswersSerializer < Decidim::Exporters::Serializer
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a collection of Answers.
      def initialize(answers)
        @answers = answers
      end

      # Public: Exports a hash with the serialized data for the user answers.
      def serialize
        @answers.each_with_index.inject({}) do |serialized, (answer, idx)|
          serialized.update(
            answer_translated_attribute_name(:id) => answer.id,
            answer_translated_attribute_name(:created_at) => answer.created_at.to_fs(:db),
            answer_translated_attribute_name(:ip_hash) => answer.ip_hash,
            answer_translated_attribute_name(:user_status) => answer_translated_attribute_name(answer.decidim_user_id.present? ? "registered" : "unregistered"),
            answer_translated_attribute_name(:task_id) => task_for(answer).id,
            answer_translated_attribute_name(:task_name) => task_for(answer).name,
            answer_translated_attribute_name(:activity_id) => activity_for(answer).id,
            answer_translated_attribute_name(:activity_description) => activity_for(answer).description,
            "#{idx + 1}. #{translated_attribute(answer.question.body)}" => normalize_body(answer)
          )
        end
      end

      private

      def normalize_body(answer)
        answer.body || normalize_choices(answer, answer.choices)
      end

      def normalize_choices(answer, choices)
        if answer.question.matrix?
          normalize_matrix_choices(answer, choices)
        else
          choices.map do |choice|
            choice.try(:custom_body) || choice.try(:body)
          end
        end
      end

      def normalize_matrix_choices(answer, choices)
        answer.question.matrix_rows.to_h do |matrix_row|
          row_body = translated_attribute(matrix_row.body)

          row_choices = answer.question.answer_options.map do |answer_option|
            choice = choices.find_by(matrix_row:, answer_option:)
            choice.try(:custom_body) || choice.try(:body)
          end

          [row_body, row_choices]
        end
      end

      def answer_translated_attribute_name(attribute)
        I18n.t(attribute.to_sym, scope: "decidim.time_tracker.time_tracker_activity_questionnaire_answers_serializer")
      end

      def task_for(answer)
        activity_for(answer).task
      end

      def activity_for(answer)
        Activity.find(answer.session_token.split("-").last)
      end
    end
  end
end
