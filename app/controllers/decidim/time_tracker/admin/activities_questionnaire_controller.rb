# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class ActivitiesQuestionnaireController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire

        def questionnaire_for
          activity
        end

        def update_url
          task_activity_form_path(activity_id: activity.id)
        end

        def after_update_url
          edit_task_activity_form_path(activity_id: activity.id)
        end

        private

        def activity
          @activity ||= Activity.find(params[:activity_id])
        end
      end
    end
  end
end
