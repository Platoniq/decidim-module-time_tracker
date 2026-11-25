# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Polled by the activity list while a join request is pending, so the
    # page can switch to the timer as soon as an admin accepts it.
    class AssignationStatusController < Decidim::TimeTracker::ApplicationController
      # Authorized by Decidim::Components::BaseController (:read on the component)
      def show # rubocop:disable Decidim/EnforcePermissionTo
        activity = time_tracker.activities.find(params[:activity_id])
        # the current user's own assignation
        assignation = Assignation.find_by(activity:, user: current_user) if user_signed_in? # rubocop:disable Decidim/OrganizationScopedFinder

        render json: { status: assignation&.status || "none" }
      end
    end
  end
end
