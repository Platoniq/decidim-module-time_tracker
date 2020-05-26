# frozen_string_literal: true

module Decidim
  module TimeTracker
    class MilestonesController < Decidim::TimeTracker::ApplicationController

      def create
        # enforce_permission_to :create, :time_entries

        CreateMilestone.call(activity, assignee, params[:time_entry]) do
          on(:ok) do |time_entry|
            render json: { message: I18n.t("time_entries.create.success", scope: "decidim.time_tracker") }
          end
          on(:error) do |message|
            render json: { message: I18n.t("time_entries.create.error", scope: "decidim.time_tracker"),
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
        Milestone.find(params[:time_entry][:id])
      end
    end
  end
end
