# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This controller is the abstract class from which all other controllers of
      # this engine inherit.
      #
      # Note that it inherits from `Decidim::Admin::Components::BaseController`, which
      # override its layout and provide all kinds of useful methods.
      class ApplicationController < Decidim::Admin::Components::BaseController
        helper_method :time_tracker

        private

        def time_tracker
          @time_tracker ||= Decidim::TimeTracker::TimeTracker.find_by(component: current_component)
        end

        # Records are always looked up through the component being
        # administered. Finding them by bare id let an admin of one space act
        # on another space's tasks, activities and assignations just by
        # changing an id in the URL: the permission checks only ever see the
        # component in the path, never the record's own.
        def scoped_task(id)
          time_tracker.tasks.find(id)
        end

        # Where to return after acting on a row that is listed on a page other
        # than its own (the pending lists on the tasks index pass their path).
        # The value comes from the query string, so only a path on this site is
        # honoured; anything else would make the admin panel an open redirect.
        def success_path
          path = params[:success_path].to_s
          return if path.blank? || !path.start_with?("/") || path.start_with?("//") || path.include?("\\")

          uri = URI.parse(path)
          path if uri.host.nil? && uri.scheme.nil?
        rescue URI::InvalidURIError
          nil
        end
      end
    end
  end
end
