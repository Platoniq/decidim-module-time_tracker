# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssignationStatusController < Decidim::TimeTracker::ApplicationController
      def show
        activity = Activity.find(params[:activity_id])
        assignation = Assignation.find_by(activity: activity, user: current_user)

        status = if assignation
                   assignation.status
                 else
                   "none"
                 end

        render json: { status: status }
      end
    end
  end
end
