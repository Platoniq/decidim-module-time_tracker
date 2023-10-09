# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a task
      class CreateTimeTracker < Rectify::Command
        def initialize(component)
          @questionnaire = Decidim::Forms::Questionnaire.new
          @assignee_questionnaire = Decidim::Forms::Questionnaire.new
          @time_tracker = Decidim::TimeTracker::TimeTracker.new(component: component, questionnaire: @questionnaire)
        end

        def call
          begin
            @time_tracker.save!
            populate_questionnaire(Decidim::TimeTracker.default_activity_questionnaire, @questionnaire)
            populate_questionnaire(Decidim::TimeTracker.default_assignee_questionnaire, @assignee_questionnaire)
            create_assignee_data
          rescue StandardError
            return broadcast(:invalid)
          end

          broadcast(:ok)
        end

        attr_reader :time_tracker, :questionnaire, :assignee_questionnaire

        private

        def populate_questionnaire(seeds, questionnaire)
          return unless seeds
          return unless seeds[:questions]

          questions = seeds[:questions].map do |question|
            Decidim::Forms::Question.create(prepare_question(question, questionnaire))
          end

          seeds[:title] = i18nize(seeds[:title])
          seeds[:description] = i18nize(seeds[:description])
          seeds[:tos] = i18nize(seeds[:tos])
          seeds[:questions] = questions

          questionnaire.attributes = seeds
        end

        def prepare_question(question, questionnaire)
          if question.has_key?(:answer_options)
            question[:answer_options].map! do |answer_option|
              answer_option[:body] = i18nize(answer_option[:body])
              Decidim::Forms::AnswerOption.new(answer_option)
            end
          end

          question.merge(
            body: i18nize(question[:body]),
            description: i18nize(question[:description]),
            questionnaire: questionnaire
          )
        end

        def create_assignee_data
          Decidim::TimeTracker::AssigneeData.create!(time_tracker: @time_tracker, questionnaire: @assignee_questionnaire)
        end

        def i18nize(key)
          return key unless key.is_a? String

          I18n.available_locales.index_with do |locale|
            I18n.with_locale(locale) { I18n.t(key, default: key) }
          end
        end
      end
    end
  end
end
