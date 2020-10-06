# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when requesting to be an assignee
    class CreateRequestAssignee < Rectify::Command
      def initialize(activity, user)
        @activity = activity
        @user = user
      end

      # Creates the meeting if valid.
      #
      # Broadcasts :ok if successful, :invalid otherwise.
      def call
        begin
          create_request_assignee
        rescue StandardError
          return broadcast(:invalid)
        end

        broadcast(:ok, activity)
      end

      private

      attr_reader :activity

      def create_request_assignee
        Decidim::TimeTracker::Assignee.create!(
          activity: @activity,
          user: @user,
          status: :pending,
          requested_at: Time.current
        )
      end
    end
  end
end
