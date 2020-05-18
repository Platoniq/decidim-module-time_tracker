# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when updating a time entry
    class UpdateTimeEntry < Rectify::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(time_entry, params)
        @time_entry = time_entry
        @params = params
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        update_timeentry
        broadcast(:ok, @time_entry)
      end

      private

      def update_timeentry
        @time_entry = Decidim.traceability.update!(
          @time_entry,
          current_user,
          time_start: @params[:time_start],
          time_end: @params[:time_end],
          elapsed_time: @params[:elapsed_time]
        )
      end
    end
  end
end
