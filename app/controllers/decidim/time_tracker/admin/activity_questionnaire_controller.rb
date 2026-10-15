# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class ActivityQuestionnaireController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire
        include Decidim::Forms::Admin::Concerns::HasQuestionnaireAnswersUrlHelper

        def questionnaire_for
          time_tracker
        end

        def questionnaire_participants_url
          Decidim::EngineRouter.admin_proxy(questionnaire_for.component).activity_questionnaire_answers_path(questionnaire_for)
        end

        def questionnaire_url
          activity_questionnaire_url
        end

        def update_url
          EngineRouter.admin_proxy(current_component).activity_questionnaire_path
        end

        def edit_questions_template
          "decidim/time_tracker/admin/activity_questionnaire/edit_questions"
        end

        # URL is a custom preview path so we can take control of the answer action
        def public_url
          activity = time_tracker.activities.first
          return unless activity

          EngineRouter.main_proxy(current_component).preview_task_activity_form_path(task_id: activity.task, activity_id: activity, id: activity.questionnaire)
        end

        def after_update_url
          if action_name == "update_questions"
            EngineRouter.admin_proxy(current_component).edit_questions_activity_questionnaire_path
          else
            EngineRouter.admin_proxy(current_component).root_path
          end
        end

        def answer_options_url(params)
          EngineRouter.admin_proxy(current_component).answer_options_activity_questionnaire_path(format: :json, **params)
        end

        def answer_options
          respond_to do |format|
            format.json do
              question_id = params["id"]
              question = Decidim::Forms::Question.find_by(id: question_id)
              if question.present?
                render json: question.answer_options.map { |answer_option| Decidim::Forms::AnswerOptionPresenter.new(answer_option).as_json }
              else
                render json: []
              end
            end
          end
        end
      end
    end
  end
end
