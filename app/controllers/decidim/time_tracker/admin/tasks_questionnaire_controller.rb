# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class TasksQuestionnaireController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire

        def questionnaire_for
          task
        end

        def update_url
          EngineRouter.admin_proxy(current_component).task_form_path(task_id: task.id)
        end

        def after_update_url
          EngineRouter.admin_proxy(current_component).edit_task_path(id: task.id)
        end

        private

        def task
          @task ||= Task.where(component: current_component).find(params[:task_id])
        end
      end
    end
  end
end
