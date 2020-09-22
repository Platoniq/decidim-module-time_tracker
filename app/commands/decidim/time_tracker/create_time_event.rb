# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when creating a time event
    class CreateTimeEvent < Rectify::Command
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

        return broadcast(:ok, @time_entry) if action_already_active?
        return broadcast(:ok, @time_entry) if action_already_stopped?

        begin
          stop_previous_activity
          create_time_event
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, @time_entry)
      end

      private

      attr_reader :current_user, :form

      def create_time_event
        @time_entry = create_time_event!(form.activity, form.action, form.total_seconds)
      end

      def create_time_event!(activity, action, total_seconds)
        Decidim.traceability.create!(
          Decidim::TimeTracker::TimeEvent,
          current_user,
          user: form.user,
          assignee: form.assignee,
          activity: activity,
          action: action,
          total_seconds: total_seconds
        )
      end

      def stop_previous_activity
        previous = TimeEvent.where.not(activity: form.activity).last_for(form.user)

        return unless previous
        return if previous.action == "stop"

        create_time_event!(
          previous.activity,
          "stop",
          [previous.seconds_elapsed, form.activity.remaining_seconds_for_the_day].min
        )
      end

      def action_already_active?
        @time_entry = form.previous_entry
        return false unless @time_entry
        return false if @time_entry.action != form.action

        elapsed = @time_entry.seconds_elapsed + form.activity.user_total_seconds_for_date(form.user, Time.current)
        elapsed < form.activity.remaining_seconds_for_the_day
      end

      def action_already_stopped?
        return false if form.action != "stop"

        @time_entry = form.previous_entry
        return true unless @time_entry

        @time_entry.action == "stop"
      end
    end
  end
end
