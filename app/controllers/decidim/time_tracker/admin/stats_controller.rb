# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class StatsController < Admin::ApplicationController
        include Paginable
        helper Decidim::TimeTracker::ApplicationHelper

        helper_method :tasks, :activities, :assignations

        def index
        end

        private

        def assignations
          paginate time_tracker.assignations.accepted
        end
      end
    end
  end
end
