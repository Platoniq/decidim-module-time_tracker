# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssigneesController < ApplicationController
        include Decidim::TimeTracker::ApplicationHelper
        helper_method :assignees, :current_task, :current_activity, :current_assignee, :assignees_label

        def index
          @assignees = assignees
        end

        def new
          enforce_permission_to :create, :assignees

          @form = form(AssigneeForm).instance
        end

        def create
          enforce_permission_to :create, :assignees

          @form = form(AssigneeForm).from_params(params)

          CreateAssignee.call(@form, current_activity) do
            on(:ok) do
              flash[:notice] = I18n.t("assignees.create.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignees_path(current_task, current_activity)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("assignees.create.error", scope: "decidim.time_tracker.admin")
              render :new
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :assignee, assignee: current_assignee

          DestroyAssignee.call(current_assignee, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("assignees.destroy.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignees_path(current_task, current_activity)
            end
          end
        end

        def update
          enforce_permission_to :update, :assignee, assignee: current_assignee

          UpdateAssignee.call(current_assignee, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("assignees.update.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignees_path(current_task, current_activity)
            end
          end
        end

        def assignees
          @assignees = Assignee.where(activity: current_activity.id)
        end

        def current_task
          @task = Task.find(params[:task_id])
        end

        def current_activity
          @activity = Activity.find(params[:activity_id])
        end

        def current_assignee
          @assignee = Assignee.find(params[:id])
        end
      end
    end
  end
end
