# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Admins verify or dismiss the pending activity completions filed when
      # participants meet an activity's completion criteria.
      class CompletionsController < Admin::ApplicationController
        def verify
          enforce_permission_to :verify, :completion, completion: current_completion

          VerifyCompletion.call(current_completion, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("completions.verify.success", scope: "decidim.time_tracker.admin")
              redirect_back_to_source
            end

            on(:invalid) do
              flash[:alert] = I18n.t("completions.verify.error", scope: "decidim.time_tracker.admin")
              redirect_back_to_source
            end
          end
        end

        def dismiss
          enforce_permission_to :dismiss, :completion, completion: current_completion

          DismissCompletion.call(current_completion, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("completions.dismiss.success", scope: "decidim.time_tracker.admin")
              redirect_back_to_source
            end

            on(:invalid) do
              flash[:alert] = I18n.t("completions.dismiss.error", scope: "decidim.time_tracker.admin")
              redirect_back_to_source
            end
          end
        end

        private

        def current_activity
          @current_activity ||= scoped_task(params[:task_id]).activities.find(params[:activity_id])
        end

        def current_assignation
          @current_assignation ||= current_activity.assignations.find(params[:assignation_id])
        end

        def current_completion
          @current_completion ||= current_assignation.completions.find(params[:id])
        end

        def redirect_back_to_source
          redirect_to success_path || EngineRouter.admin_proxy(current_component).task_activity_assignations_path(current_activity.task, current_activity)
        end
      end
    end
  end
end
