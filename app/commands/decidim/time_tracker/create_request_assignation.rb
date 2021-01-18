# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when requesting to be an assignation
    class CreateRequestAssignation < Rectify::Command
      def initialize(activity, user)
        @activity = activity
        @user = user
      end

      # Creates the assignation if valid.
      #
      # Broadcasts :ok if successful, :invalid otherwise.
      def call
        begin
          create_request_assignation
        rescue StandardError
          return broadcast(:invalid)
        end

        broadcast(:ok, activity)
      end

      private

      attr_reader :activity

      def create_request_assignation
        Decidim::TimeTracker::Assignation.create!(
          activity: @activity,
          user: @user,
          status: :pending,
          requested_at: Time.current
        )
      end
    end
  end
end
