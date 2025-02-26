# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssigneeQuestionnaireController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire
        include Decidim::Forms::Admin::Concerns::HasQuestionnaireAnswers

        # only allows answers if not in preview mode
        def allow_answers?
          return false unless current_user

          return true if params[:action] == "preview" && current_user.admin?

          activity.allow_answers_for? current_user
        end

        def questionnaire_for
          time_tracker.assignee_data
        end

        def questionnaire_participants_url
          index_assignee_questionnaire_url
        end

        def questionnaire_url
          assignee_questionnaire_url
        end

        def questionnaire_participant_answers_url(session_token)
          show_assignee_questionnaire_url(session_token:)
        end

        def questionnaire_export_response_url(session_token)
          export_response_assignee_questionnaire_url(session_token:, format: "pdf")
        end

        def update_url
          EngineRouter.admin_proxy(current_component).assignee_questionnaire_path
        end

        # URL is a custom preview path so we can take control of the answer action
        def public_url
          EngineRouter.main_proxy(current_component).preview_assignee_questionnaire_path
        end

        def after_update_url
          EngineRouter.admin_proxy(current_component).root_path
        end

        def answer_options_url(params)
          EngineRouter.admin_proxy(current_component).answer_options_assignee_questionnaire_path(format: :json, **params)
        end
      end
    end
  end
end
