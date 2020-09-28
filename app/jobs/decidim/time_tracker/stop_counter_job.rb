# frozen_string_literal: true

module Decidim
  # This jobs stops a counter if is over timed
  module TimeTracker
    class StopCounterJob < ApplicationJob
      queue_as :default

      # time_event - the counter to stop, only stopped if it's due time is reached
      def perform(time_event)
        @time_event = time_event
        return if @time_event.stopped?
        return if time_available?

        @time_event.stop!
      end

      private

      def time_available?
        date = Time.zone.at(@time_event.start)
        last_elapsed = @time_event.seconds_elapsed
        remaining = @time_event.activity.user_remaining_for_date(@time_event.user, date)

        remaining > last_elapsed
      end
    end
  end
end
