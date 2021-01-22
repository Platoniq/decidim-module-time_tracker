# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeQuestionnaireController < Decidim::TimeTracker::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      # only allows answers if not in preview mode
      def preview
        return show if request.method == "GET"

        flash[":alert"] = I18n.t("questionnaire_in_preview_mode", scope: "decidim.time_tracker.time_tracker")
        redirect_to preview_assignee_questionnaire_path
      end

      # overwrite this method to automatically accept TOS
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

      # only allows answers if not in preview mode
      def allow_answers?
        return false if current_user.blank?

        return true if params[:action] == "preview" && current_user.admin?

        current_component.published?
      end

      # Override so can answer only if is an assignation can view
      # Also admins can preview it (but not answer)
      def visitor_can_answer?
        return false if current_user.blank?

        params[:action] == "preview" && current_user.admin?
      end

      def visitor_already_answered?
        !visitor_can_answer?
      end

      # Returns the path to answer this questionnaire for normal users
      # If the questionnaire is rendered in a preview route, then just do nothing with the responses
      def update_url
        return preview_assignee_questionnaire_path if params[:action] == "preview"

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
