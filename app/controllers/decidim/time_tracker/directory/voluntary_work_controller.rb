# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Directory
      # The controller to handle the user's voluntary work page.
      class VoluntaryWorkController < Decidim::ApplicationController
        include Decidim::UserProfile
        helper_method :activities, :assignees
        # layout "layouts/decidim/application"

        def index
          enforce_permission_to :read, :user, current_user: current_user
        end

        private

        def assignees
          Assignee.where(user: current_user)
        end

        def activities
          Decidim::TimeTracker:: Activity.joins(:assignees).where("decidim_time_tracker_assignees.decidim_user_id": current_user.id).group_by(&:id)
        end
      end
    end
  end
end
