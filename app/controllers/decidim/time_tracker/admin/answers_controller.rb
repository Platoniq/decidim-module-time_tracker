# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AnswersController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaireAnswers

        def index
          enforce_permission_to :index, :questionnaire_answers

          @query = paginate(collection)
          @participants = participants(@query)
          @total = questionnaire.count_participants

          render template: "decidim/time_tracker/admin/questionnaire_answers/index"
        end

        def show
          enforce_permission_to :show, :questionnaire_answers

          @participant = participant(participants_query.participant(params[:id]))

          render template: "decidim/time_tracker/admin/questionnaire_answers/show"
        end

        private

        def questionnaire
          @questionnaire ||= Decidim::Forms::Questionnaire.find_by(questionnaire_for:)
        end

        def participants_query
          Decidim::Forms::QuestionnaireParticipants.new(questionnaire)
        end

        def collection
          @collection ||= participants_query.participants
        end

        def participant(answer)
          Decidim::Forms::Admin::QuestionnaireParticipantPresenter.new(participant: answer)
        end

        def participants(query)
          query.map { |answer| participant(answer) }
        end
      end
    end
  end
end
