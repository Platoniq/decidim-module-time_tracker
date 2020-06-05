# frozen_string_literal: true

module Decidim
  module TimeTracker
    class MilestonesController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      def create
        # enforce_permission_to :create, :time_entries

        @form = form(AttachmentForm).from_params(params)

        CreateMilestone.call(@form) do
          on(:ok) do |milestone|
            time_entry = current_time_entry
            time_entry.milestone = milestone
            time_entry.save!
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
        @time_entry = TimeEntry.find(params[:time_entry_id])
      end
    end
  end
end
