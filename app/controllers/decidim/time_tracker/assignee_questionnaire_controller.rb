# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeQuestionnaireController < Decidim::TimeTracker::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

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
