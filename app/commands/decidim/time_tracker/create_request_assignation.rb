# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when requesting to be an assignation
    class CreateRequestAssignation < Decidim::Command
      def initialize(activity, user)
        @activity = activity
        @user = user
      end

      # Creates the assignation if valid.
      #
      # Broadcasts :ok if successful, :invalid otherwise.
      def call
        begin
          accept_terms_by_joining
          create_request_assignation
          notify_admins
        rescue StandardError
          return broadcast(:invalid)
        end

        broadcast(:ok, activity)
      end

      private

      attr_reader :activity

      def notify_admins
        Decidim::EventsManager.publish(
          event: "decidim.events.time_tracker.assignation_requested_event",
          event_class: Decidim::TimeTracker::AssignationRequestedEvent,
          resource: activity,
          followers: activity.task.component.participatory_space.admins,
          # Admins have to act on it, so it is emailed whatever their digest setting.
          extra: { participant_name: @user.name, force_email: true }
        )
      end

      # When the "About you" questionnaire asks nothing, the join request is the
      # volunteer's acceptance of the terms; recording it keeps "joined at" and
      # the admin's terms column right.
      def accept_terms_by_joining
        time_tracker = activity.task.time_tracker
        return if time_tracker.has_assignee_questions?

        assignee = Decidim::TimeTracker::Assignee.for(@user)
        Decidim::TimeTracker::TosAcceptance.create!(assignee:, time_tracker:) unless assignee.tos_accepted?(time_tracker)
      end

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
