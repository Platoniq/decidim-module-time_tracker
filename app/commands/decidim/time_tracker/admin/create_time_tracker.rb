# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a task
      class CreateTimeTracker < Decidim::Command
        def initialize(component)
          @questionnaire = Decidim::Forms::Questionnaire.new
          @assignee_questionnaire = Decidim::Forms::Questionnaire.new
          @time_tracker = Decidim::TimeTracker::TimeTracker.new(component:, questionnaire: @questionnaire)
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

          questions = seeds[:questions].each_with_index.map do |question, index|
            Decidim::Forms::Question.create(prepare_question(question, questionnaire, index + 1))
          end

          seeds[:title] = i18nize(seeds[:title])
          seeds[:description] = i18nize(seeds[:description])
          seeds[:tos] = i18nize(seeds[:tos])
          seeds[:questions] = questions

          questionnaire.attributes = seeds
        end

        # The seed files keep the answer_options key they have always
        # documented; Decidim 0.31 calls the association response_options, and
        # passing the old name made every new time tracker fail to save.
        def prepare_question(question, questionnaire, position)
          options = question.delete(:answer_options) || question.delete(:response_options)
          if options
            question[:response_options] = options.map do |option|
              Decidim::Forms::ResponseOption.new(option.merge(body: i18nize(option[:body])))
            end
          end

          question.reverse_merge(position:).merge(
            body: i18nize(question[:body]),
            description: i18nize(question[:description]),
            questionnaire:
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
