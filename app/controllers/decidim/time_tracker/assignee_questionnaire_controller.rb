# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeQuestionnaireController < Decidim::TimeTracker::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      def answer
        enforce_permission_to :answer, :questionnaire

        @form = form(Decidim::Forms::QuestionnaireForm).from_params(params, session_token: session_token, ip_hash: ip_hash)

        Decidim::Forms::AnswerQuestionnaire.call(@form, current_user, questionnaire) do
          on(:ok) do
            # i18n-tasks-use t("decidim.forms.questionnaires.answer.success")
            TosAcceptance.create!(assignee: Assignee.for(current_user), time_tracker: time_tracker)
            flash[:notice] = I18n.t("answer.success", scope: i18n_flashes_scope)
            redirect_to after_answer_path
          end

          on(:invalid) do
            # i18n-tasks-use t("decidim.forms.questionnaires.answer.invalid")
            flash.now[:alert] = I18n.t("answer.invalid", scope: i18n_flashes_scope)
            render template: "decidim/forms/questionnaires/show"
          end
        end
      end

      def questionnaire_for
        time_tracker.assignee_data
      end

      def allow_answers?
        current_user.present? && current_component.published?
      end

      def update_url
        answer_assignee_questionnaire_path
      end

      def form_path
        assignee_questionnaire_path
      end

      def after_answer_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end
    end
  end
end
