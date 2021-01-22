# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class ActivityQuestionnaireController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire
        include Decidim::Forms::Admin::Concerns::HasQuestionnaireAnswers

        def questionnaire_for
          time_tracker
        end

        def questionnaire_participants_url
          index_activity_questionnaire_url
        end

        def questionnaire_url
          activity_questionnaire_url
        end

        def questionnaire_participant_answers_url(session_token)
          show_activity_questionnaire_url(session_token: session_token)
        end

        def questionnaire_export_response_url(session_token)
          export_response_activity_questionnaire_url(session_token: session_token, format: "pdf")
        end

        def update_url
          EngineRouter.admin_proxy(current_component).activity_questionnaire_path
        end

        def public_url
          activity = time_tracker.activities.first
          return unless activity

          EngineRouter.main_proxy(current_component).preview_task_activity_form_path(task_id: activity.task, activity_id: activity, id: activity.questionnaire)
        end

        def after_update_url
          EngineRouter.admin_proxy(current_component).root_path
        end

        def answer_options_url(params)
          EngineRouter.admin_proxy(current_component).answer_options_activity_questionnaire_path(format: :json, **params)
        end
      end
    end
  end
end
