# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeEntriesController < Decidim::TimeTracker::ApplicationController
      helper_method :activity, :task

      def create
        # enforce_permission_to :create, :time_entries

        CreateTimeEntry.call(activity, assignee, params[:time_entry]) do
          on(:ok) do |time_entry|
            render json: { message: I18n.t("time_entries.create.success", scopre: "decidim.time_tracker"),
                           time_entry_id: time_entry.id,
                           time_start: time_entry.time_start,
                           time_end: time_entry.time_end }
          end
          on(:error) do |message|
            render json: { message: I18n.t("time_entries.create.error", scope: "decidim.time_tracker"),
                           error: message }
          end
        end
      end

      def update
        # enforce_permission_to :update, :time_entries

        UpdateTimeEntry.call(current_time_entry, params[:time_entry]) do
          on(:ok) do |time_entry|
            render json: { message: I18n.t("time_entries.update.success", scopre: "decidim.time_tracker"),
                           time_entry_id: time_entry.id,
                           time_start: time_entry.time_start,
                           time_end: time_entry.time_end }
          end
          on(:error) do |message|
            render json: { message: I18n.t("time_entries.update.error", scope: "decidim.time_tracker"),
                           error: message }
          end
        end
      end

      def task
        Task.find(params[:task_id])
      end

      def activity
        Activity.find(params[:activity_id])
      end

      def assignee
        Assignee.find_by(user: current_user.id, activity: activity.id)
      end

      def current_time_entry
        TimeEntry.find(params[:time_entry][:id])
      end
    end
  end
end
