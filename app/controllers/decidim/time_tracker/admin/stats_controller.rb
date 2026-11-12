# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class StatsController < Admin::ApplicationController
        include Paginable
        include Decidim::TimeTracker::Admin::FilterableAssignations

        helper Decidim::TimeTracker::ApplicationHelper

        helper_method :assignations

        # Authorized by Decidim::Admin::Components::BaseController#enforce_component_permissions
        def index; end # rubocop:disable Decidim/EnforcePermissionTo

        private

        def assignations_collection
          @assignations_collection ||= Decidim::TimeTracker::Assignation.joins(:task).where(decidim_time_tracker_tasks: { time_tracker_id: time_tracker.id }) # rubocop:disable Decidim/OrganizationScopedFinder -- scoped to this time tracker
        end

        alias assignations filtered_collection
      end
    end
  end
end
