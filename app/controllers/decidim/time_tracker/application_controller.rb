# frozen_string_literal: true

module Decidim
  module TimeTracker
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper_method :time_tracker, :current_assignee, :tasks, :global_progress

      private

      def time_tracker
        @time_tracker ||= Decidim::TimeTracker::TimeTracker.find_by(component: current_component)
      end

      def current_assignee
        return nil unless user_signed_in?

        @current_assignee ||= Decidim::TimeTracker::Assignee.for(current_user)
      end

      def global_progress
        all_tasks = tasks
        return nil if all_tasks.empty?

        valid_progresses = all_tasks.map(&:progress).compact
        return nil if valid_progresses.empty?

        (valid_progresses.sum.to_f / valid_progresses.size).round
      end

      def tasks
        return [] if time_tracker.blank?

        time_tracker.tasks
      end
    end
  end
end
