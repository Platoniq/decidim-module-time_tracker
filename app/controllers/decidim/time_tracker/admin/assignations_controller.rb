# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssignationsController < Admin::ApplicationController
        helper Decidim::TimeTracker::ApplicationHelper
        helper Decidim::TimeTracker::Admin::ApplicationHelper
        helper_method :assignations, :current_task, :current_activity, :current_assignation

        def index
          @assignations = assignations
        end

        def new
          enforce_permission_to :create, :assignations

          @form = form(AssignationForm).instance
        end

        def create
          enforce_permission_to :create, :assignations

          @form = form(AssignationForm).from_params(params)

          CreateAssignation.call(@form, current_activity) do
            on(:ok) do
              flash[:notice] = I18n.t("assignations.create.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignations_path(current_task, current_activity)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("assignations.create.error", scope: "decidim.time_tracker.admin")
              render :new
            end
          end
        end

        def update
          enforce_permission_to :update, :assignation, assignation: current_assignation

          UpdateAssignation.call(current_assignation, current_user, params[:assignation_status].to_sym) do
            on(:ok) do
              flash[:notice] = I18n.t("assignations.update.success", scope: "decidim.time_tracker.admin")
              if params[:success_path].present?
                redirect_to params[:success_path]
              else
                redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignations_path(current_task, current_activity)
              end
            end
          end
        end

        def complete
          enforce_permission_to :complete, :assignation, assignation: current_assignation

          CompleteAssignation.call(current_assignation, current_user, complete: params[:revert].blank?) do
            on(:ok) do
              flash[:notice] = I18n.t("assignations.complete.success", scope: "decidim.time_tracker.admin")
              redirect_back_to_assignations
            end

            on(:invalid) do
              flash[:alert] = I18n.t("assignations.complete.error", scope: "decidim.time_tracker.admin")
              redirect_back_to_assignations
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :assignation, assignation: current_assignation

          DestroyAssignation.call(current_assignation, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("assignations.destroy.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignations_path(current_task, current_activity)
            end
          end
        end

        # obtaining the users separately to have them ordered in a nice way
        def assignations
          @assignations = Assignation.where(activity: current_activity.id).sorted_by_status(:pending, :accepted, :rejected)
        end

        def current_task
          @current_task ||= Task.find(params[:task_id])
        end

        def current_activity
          @current_activity ||= Activity.find(params[:activity_id])
        end

        def current_assignation
          @current_assignation ||= Assignation.find(params[:id])
        end

        def redirect_back_to_assignations
          if params[:success_path].present?
            redirect_to params[:success_path]
          else
            redirect_to EngineRouter.admin_proxy(current_component).task_activity_assignations_path(current_task, current_activity)
          end
        end
      end
    end
  end
end
