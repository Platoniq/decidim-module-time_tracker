# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Stops the last event for the user
    class StopLastTimeEvent < Decidim::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(current_user)
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:already_stopped, @last_entry) if last_entry.stopped?

        begin
          stop_time_event!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, @last_entry)
      end

      attr_reader :current_user, :form

      private

      def last_entry
        @last_entry ||= Decidim::TimeTracker::TimeEvent.last_for(current_user)
      end

      def stop_time_event!
        last_entry.stop!
      end
    end
  end
end
