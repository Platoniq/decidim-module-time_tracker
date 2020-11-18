# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssignationsController < Decidim::TimeTracker::ApplicationController
      helper_method :assignation

      def create
        enforce_permission_to :create, :assignation, activity: activity

        CreateRequestAssignation.call(activity, current_user) do
          on(:ok) do |activity|
            render json: {
              message: I18n.t("assignations.request.success", scope: "decidim.time_tracker"),
              activityId: activity.id
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
        @activity ||= Activity.active.find_by(id: params[:activity_id])
      end

      def assignation
        @assignation ||= Assignation.accepted.find_by(id: params[:id])
      end
    end
  end
end
