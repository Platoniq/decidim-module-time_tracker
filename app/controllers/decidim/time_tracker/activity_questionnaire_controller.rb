# frozen_string_literal: true

module Decidim
  module TimeTracker
    class ActivityQuestionnaireController < Decidim::TimeTracker::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      # only allows answers if not in preview mode
      def preview
        return show if request.method == "GET"

        flash[":alert"] = I18n.t("questionnaire_in_preview_mode", scope: "decidim.time_tracker.time_tracker")
        redirect_to preview_task_activity_form_path(activity_id: activity.id, id: activity.questionnaire)
      end

      def questionnaire_for
        time_tracker
      end

      # only allows answers if not in preview mode
      def allow_answers?
        return false if current_user.blank?

        return true if params[:action] == "preview" && current_user.admin?

        activity.allow_answers_for? current_user
      end

      # Returns the path to answer this questionnaire for normal users
      # If the questionnaire is rendered in a preview route, then just do nothing with the responses
      def update_url
        return preview_task_activity_form_path(activity_id: activity.id, id: activity.questionnaire) if params[:action] == "preview"

        answer_task_activity_form_path(activity_id: activity.id, id: activity.questionnaire)
      end

      def form_path
        task_activity_form_path(activity_id: activity.id, id: activity.questionnaire)
      end

      def after_answer_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end

      # Override so can answer only if is an assignation can view
      # Also admins can preview it (but not answer)
      def visitor_can_answer?
        return false if current_user.blank?

        return true if params[:action] == "preview" && current_user.admin?

        activity.assignation_accepted? current_user
      end

      # Override to allow respond users once per-activity
      def visitor_already_answered?
        return false if current_user.blank?

        return true if params[:action] == "preview" && current_user.admin?

        activity.questionnaire.answered_by?(session_token)
      end

      private

      # Override to enable response once for each activity
      def session_token
        activity.session_token(current_user)
      end

      def activity
        @activity ||= Activity.find(params[:activity_id])
      end
    end
  end
end
