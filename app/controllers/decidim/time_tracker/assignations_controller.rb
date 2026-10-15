# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssignationsController < Decidim::TimeTracker::ApplicationController
      helper_method :assignation

      def create
        enforce_permission_to(:create, :assignation, activity:)

        CreateRequestAssignation.call(activity, current_user) do
          on(:ok) do |activity|
            render json: {
              message: I18n.t("assignations.request.success", scope: "decidim.time_tracker"),
              activityId: activity.id,
              # The same "Request sent" state the page shows after a reload, so
              # the row keeps its layout; the message is shown on its own.
              html: render_to_string(partial: "decidim/time_tracker/time_tracker/activity_action", formats: [:html],
                                     locals: { activity:, assignation: Assignation.find_by(activity:, user: current_user),
                                               timer_path: "#activity-#{activity.id}" })
            }
          end

          on(:invalid) do
            render json: {
              message: I18n.t("assignations.request.error", scope: "decidim.time_tracker")
            }, status: :unprocessable_entity
          end
        end
      end

      private

      def activity
        @activity ||= time_tracker.activities.active.find_by(id: params[:activity_id])
      end

      def assignation
        @assignation ||= Assignation.accepted.find_by(id: params[:id])
      end
    end
  end
end
