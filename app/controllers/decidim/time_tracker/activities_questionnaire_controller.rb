# frozen_string_literal: true

module Decidim
  module TimeTracker
    class ActivitiesQuestionnaireController < ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      def answer; end

      def questionnaire_for
        activity if activity.has_questions?
        task
      end

      def allow_answers?
        activity.current_status == :open
      end

      def update_url
        answer_task_activities_path(task_id: task.id, activity_id: activity.id)
      end

      def after_update_url
        edit_task_form_path(task_id: task.id)
      end

      def form_path
        answer_task_activities_path(task_id: task.id)
      end

      def after_answer_path
        Decidim::EngineRouter.main_proxy(current_component).assignees_path(activity_id: activity.id)
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
