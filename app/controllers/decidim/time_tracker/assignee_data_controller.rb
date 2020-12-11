# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeDataController < Decidim::TimeTracker::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      def questionnaire_for
        time_tracker.assignee_data
      end

      def allow_answers?
        true
      end

      def update_url
        answer_assignee_data_path(id: time_tracker.assignee_questionnaire)
      end

      def form_path
        assignee_data_path(id: time_tracker.assignee_questionnaire)
      end

      def after_answer_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end

      def visitor_can_answer?
        true
      end

      private

      # Override to enable response once for each activity
      def session_token
        "123123123"
      end
    end
  end
end
