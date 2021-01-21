# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class TasksController < Admin::ApplicationController
        include Decidim::TimeTracker::ApplicationHelper
        helper_method :tasks, :current_task, :assignations, :tasks_label, :activities_label, :assignations_label

        delegate :tasks, to: :time_tracker

        def index
          @tasks = tasks
        end

        def new
          enforce_permission_to :create, :task

          @form = form(TaskForm).instance
        end

        def edit
          enforce_permission_to :update, :task, task: current_task
          @form = form(TaskForm).from_model(current_task, endpoint: current_task)
        end

        def create
          enforce_permission_to :create, :task

          @form = form(TaskForm).from_params(params)

          CreateTask.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("tasks.create.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).tasks_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("tasks.create.error", scope: "decidim.time_tracker.admin")
              render :new
            end
          end
        end

        def update
          enforce_permission_to :update, :task, task: current_task

          form = form(TaskForm).from_params(params, task: current_task)

          UpdateTask.call(current_task, form, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("tasks.update.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).edit_task_path(current_task)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("tasks.update.error", scope: "decidim.time_tracker.admin")
              render :edit
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :task, task: current_task

          DestroyTask.call(current_task, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("tasks.destroy.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).tasks_path
            end
          end
        end

        def accept_all_pending_assignations
          return redirect_to(tasks_path) if assignations.blank?

          ok = ko = 0
          assignations.each do |assignation|
            UpdateAssignation.call(assignation, current_user, :accepted) do
              on(:ok) do
                ok += 1
              end

              on(:invalid) do
                ko += 1
              end
            end
          end

          flash[:notice] = I18n.t("tasks.assignations.bulk_ok", scope: "decidim.time_tracker.admin", count: ok) if ok.positive?
          flash[:alert] = I18n.t("tasks.assignations.bulk_ko", scope: "decidim.time_tracker.admin", count: ko) if ko.positive?

          redirect_to(tasks_path)
        end

        private

        def tasks
          time_tracker.tasks
        end

        def assignations
          time_tracker.assignations.pending
        end

        def current_task
          @current_task ||= Task.find(params[:id])
        end
      end
    end
  end
end
