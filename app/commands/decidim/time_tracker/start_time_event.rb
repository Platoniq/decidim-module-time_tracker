# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when creating a time event
    class StartTimeEvent < Rectify::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form, current_user)
        @form = form
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid, form.errors&.first&.second) if form.invalid?

        return broadcast(:ok, @time_entry) if already_active?

        return broadcast(:invalid, form.errors&.first&.second) if activity_invalid?

        begin
          stop_previous_activity
          create_time_event!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, @time_entry)
      end

      attr_reader :current_user, :form

      private

      def activity_invalid?
        unless activity_started?
          form.errors.add(:activity, :not_started)
          return true
        end

        if activity_finished?
          form.errors.add(:activity, :finished)
          return true
        end

        unless time_available?
          form.errors.add(:activity, :no_time_available)
          return true
        end
      end

      def create_time_event!
        @time_entry = Decidim::TimeTracker::TimeEvent.create!(
          user: form.user,
          assignee: form.assignee,
          activity: form.activity,
          start: start
        )
      end

      def start
        form.start.presence || Time.current
      end

      def stop_previous_activity
        previous = TimeEvent.where.not(activity: form.activity).last_for(form.user)

        return unless previous
        return if previous.stopped? && previous.stop.to_i < start.to_i

        previous.stop = start.to_i
        previous.total_seconds = previous.stop - previous.start
        previous.save!
      end

      def already_active?
        @time_entry = TimeEvent.where(activity: form.activity).last_for(form.user)

        return false unless @time_entry

        elapsed = (start.to_i - @time_entry.start) + form.activity.user_total_seconds_for_date(form.user, start)
        elapsed < form.activity.remaining_seconds_for_the_day
      end

      def activity_started?
        form.activity.start_date.beginning_of_day <= start
      end

      def activity_finished?
        form.activity.end_date.end_of_day <= start
      end

      def time_available?
        form.activity.user_total_seconds_for_date(form.user, start) < form.activity.remaining_seconds_for_the_day
      end
    end
  end
end
