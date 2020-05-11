# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when updating an activity
    class CreateTimeEntry < Rectify::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(activity, assignee, params)
        @activity = activity
        @assignee = assignee
        @params = params
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        create_timeentry
        broadcast(:ok, @time_entry)
      end

      private

      def create_timeentry
        @time_entry = Decidim.traceability.create!(
          Decidim::TimeTracker::TimeEntry,
          current_user,
          activity: @activity,
          assignee: @assignee,
          time_start: @params[:time_start]
        )
      end
    end
  end
end
