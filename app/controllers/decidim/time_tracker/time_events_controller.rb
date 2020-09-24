# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeEventsController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper_method :activity, :task, :assignee

      def start
        enforce_permission_to :start, :time_events

        form = form(TimeEventForm).from_params(activity: activity, assignee: assignee)
        StartTimeEvent.call(form) do
          on(:ok) do |time_event|
            render json: { message: I18n.t("time_events.start.success", scope: "decidim.time_tracker"),
                           time_entry_id: time_event.id,
                           start: time_event.start,
                           time_start: time_event.start_time.iso8601 }
          end
          on(:error) do |message|
            render json: { message: I18n.t("time_events.start.error", scope: "decidim.time_tracker"),
                           error: message }
          end
        end
      end

      def stop
        enforce_permission_to :stop, :time_events
        
        StopLastTimeEvent.call(current_user) do
          on(:ok) do |time_event|
            render json: { message: I18n.t("time_events.stop.success", scope: "decidim.time_tracker"),
                           time_entry: time_event.to_json }
          end
          on(:error) do |message|
            render json: { message: I18n.t("time_events.stop.error", scope: "decidim.time_tracker"),
                           error: message }
          end
        end
      end

      private

      def task
        Task.find(params[:task_id])
      end

      def activity
        Activity.find(params[:activity_id])
      end

      def assignee
        Assignee.find_by(user: current_user.id, activity: activity.id)
      end
    end
  end
end
