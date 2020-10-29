# frozen_string_literal: true

module Decidim
  module TimeTracker
    class ActivitiesQuestionnaireController < ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      def questionnaire_for
        task
      end

      def allow_answers?
        activity.current_status != :inactive
      end

      def update_url
        answer_task_activity_form_path(task_id: task.id, activity_id: activity.id, id: activity.questionnaire)
      end

      def form_path
        task_activity_form_path(task_id: task.id, activity_id: activity.id, id: activity.questionnaire)
      end

      def after_answer_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end

      private

      def activity
        @activity ||= Activity.find(params[:activity_id])
      end

      def task
        @task ||= Task.where(component: current_component).find(params[:task_id])
      end
    end
  end
end
