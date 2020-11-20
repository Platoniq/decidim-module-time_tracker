# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a task
      class CreateTimeTracker < Rectify::Command
        def initialize(component)
          @questionnaire = Decidim::Forms::Questionnaire.new
          @time_tracker = Decidim::TimeTracker::TimeTracker.new(component: component, questionnaire: @questionnaire)
          populate_questionnaire
        end

        def call
          return broadcast(:ok) if @time_tracker.save

          broadcast(:invalid)
        end

        attr_reader :time_tracker, :questionnaire

        private

        def populate_questionnaire
          @seeds = Decidim::TimeTracker.default_questionnaire
          return unless @seeds

          if @seeds[:questions]&.first.is_a?(Hash)
            questions = @seeds[:questions].map do |question|
              if question.has_key?(:answer_options)
                answer_options = question.delete(:answer_options)
                answer_options.map! { |answer_option| Decidim::Forms::AnswerOption.new(answer_option) }
                question[:answer_options] = answer_options
              end

              Decidim::Forms::Question.create(question.merge(questionnaire: @questionnaire))
            end

            @seeds[:questions] = questions
          end

          @questionnaire.attributes = @seeds
        end
      end
    end
  end
end
