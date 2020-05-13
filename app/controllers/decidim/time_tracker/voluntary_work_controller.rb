# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The controller to handle the user's voluntary work page.
    class VoluntaryWorkController < Decidim::TimeTracker::ApplicationController
      include Decidim::UserProfile

      def index
        # enforce_permission_to :read, :user, current_user: current_user
      end
    end
  end
end
