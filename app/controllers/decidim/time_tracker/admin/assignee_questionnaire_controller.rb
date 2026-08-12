# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssigneeQuestionnaireController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire
        include Decidim::Forms::Admin::Concerns::HasQuestionnaireAnswersUrlHelper

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
          Decidim::EngineRouter.admin_proxy(questionnaire_for.component).assignee_questionnaire_answers_path(questionnaire_for)
        end

        def questionnaire_url
          assignee_questionnaire_url
        end

        def update_url
          EngineRouter.admin_proxy(current_component).assignee_questionnaire_path
        end

        def edit_questions_template
          "decidim/time_tracker/admin/assignee_questionnaire/edit_questions"
        end

        # URL is a custom preview path so we can take control of the answer action
        def public_url
          EngineRouter.main_proxy(current_component).preview_assignee_questionnaire_path
        end

        def after_update_url
          if action_name == "update_questions"
            EngineRouter.admin_proxy(current_component).edit_questions_assignee_questionnaire_path
          else
            EngineRouter.admin_proxy(current_component).root_path
          end
        end

        def answer_options_url(params)
          EngineRouter.admin_proxy(current_component).answer_options_assignee_questionnaire_path(format: :json, **params)
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
