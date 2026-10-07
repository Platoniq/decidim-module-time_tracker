# frozen_string_literal: true

module Decidim
  module TimeTracker
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper_method :time_tracker, :current_assignee, :tasks, :task_list, :global_progress

      private

      def time_tracker
        @time_tracker ||= Decidim::TimeTracker::TimeTracker.find_by(component: current_component)
      end

      def current_assignee
        return nil unless user_signed_in?

        @current_assignee ||= Decidim::TimeTracker::Assignee.for(current_user)
      end

      # The tasks, activities and per-visitor state every public page reads,
      # loaded once per request.
      def task_list
        @task_list ||= TaskList.new(time_tracker, current_user)
      end

      def global_progress
        return if time_tracker.blank?

        task_list.global_progress
      end

      def tasks
        return [] if time_tracker.blank?

        time_tracker.tasks
      end
    end
  end
end
