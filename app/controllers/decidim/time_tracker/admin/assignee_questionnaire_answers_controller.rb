# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssigneeQuestionnaireAnswersController < AnswersController
        def questionnaire_for
          time_tracker.assignee_data
        end

        def questionnaire_export_response_url(id)
          Decidim::EngineRouter.admin_proxy(questionnaire_for.component).export_response_assignee_questionnaire_answer_path(questionnaire_for, id:)
        end

        def questionnaire_url
          Decidim::EngineRouter.admin_proxy(questionnaire_for.component).edit_questions_assignee_questionnaire_path(questionnaire_for)
        end

        # Specify where to redirect after exporting a user response
        def questionnaire_participant_answers_url(id)
          Decidim::EngineRouter.admin_proxy(questionnaire_for.component).assignee_questionnaire_answer_path(questionnaire_for, id:)
        end

        def questionnaire_participants_url
          Decidim::EngineRouter.admin_proxy(questionnaire_for.component).assignee_questionnaire_answers_path(questionnaire_for)
        end
      end
    end
  end
end
