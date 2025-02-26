# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Reports
      # The controller to handle the user's time_tracker report page.
      class UserController < Decidim::ApplicationController
        include Decidim::ComponentPathHelper
        include Decidim::UserProfile

        helper Decidim::TimeTracker::ApplicationHelper
        helper_method :activities, :assignations, :total_time, :activity_path

        def index
          enforce_permission_to :read, :user, current_user:
        end

        private

        def activities
          Decidim::TimeTracker::Activity.joins(:assignations).where("decidim_time_tracker_assignations.decidim_user_id": current_user.id).group_by(&:id)
        end

        def assignations
          Assignation.where(user: current_user).sorted_by_status(:accepted, :pending, :rejected)
        end

        def activity_path(assignation)
          EngineRouter.main_proxy(assignation.task.time_tracker.component).root_path(locale: params[:locale], activity: assignation.activity)
        end

        def total_time
          assignations.map(&:time_dedicated).sum
        end
      end
    end
  end
end
