# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class StatsController < Admin::ApplicationController
        include Paginable
        include Decidim::TimeTracker::Admin::FilterableAssignations

        helper Decidim::TimeTracker::ApplicationHelper

        helper_method :tasks, :activities, :assignations

        def index; end

        def assignations_collection
          @assignations_collection ||= Decidim::TimeTracker::Assignation.joins(:task).where(decidim_time_tracker_tasks: { time_tracker_id: time_tracker.id })
        end

        alias assignations filtered_collection
      end
    end
  end
end
