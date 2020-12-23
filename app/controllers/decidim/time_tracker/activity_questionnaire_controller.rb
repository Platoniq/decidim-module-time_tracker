# frozen_string_literal: true

module Decidim
  module TimeTracker
    class ActivityQuestionnaireController < Decidim::TimeTracker::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      def questionnaire_for
        time_tracker
      end

      def allow_answers?
        activity.allow_answers_for? current_user
      end

      def update_url
        answer_task_activity_form_path(activity_id: activity.id, id: activity.questionnaire)
      end

      def form_path
        task_activity_form_path(activity_id: activity.id, id: activity.questionnaire)
      end

      def after_answer_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end

      # Override so can answer only if is an assignation
      def visitor_can_answer?
        activity.assignation_accepted? current_user
      end

      # Override to allow respond users once per-activity
      def visitor_already_answered?
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