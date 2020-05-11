# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The controller to handle the user's voluntary work page.
    class VoluntaryWorkController < Decidim::ApplicationController
      include Decidim::UserProfile
    end
  end
end
