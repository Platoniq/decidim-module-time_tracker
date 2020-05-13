# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Directory
      # The controller to handle the user's voluntary work page.
      class VoluntaryWorkController < Decidim::ApplicationController
        include Decidim::UserProfile
        # layout "layouts/decidim/application"

        def index
          # enforce_permission_to :read, :user, current_user: current_user"
        end
      end
    end
  end
end
