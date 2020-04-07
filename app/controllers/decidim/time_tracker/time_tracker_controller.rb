# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      helper_method :tasks

      private

      def tasks
        Task.where(component: current_component)
      end
    end
  end
end
