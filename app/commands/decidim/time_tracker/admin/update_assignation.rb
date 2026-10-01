# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an assignation
      class UpdateAssignation < Decidim::Command
        EVENTS = {
          accepted: Decidim::TimeTracker::AssignationAcceptedEvent,
          rejected: Decidim::TimeTracker::AssignationRejectedEvent
        }.freeze

        # Public: Initializes the command.
        #
        # assignation_status - A symbol representing the assignation status.
        def initialize(assignation, user, assignation_status)
          @assignation = assignation
          @user = user
          @assignation_status = assignation_status
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless [:accepted, :rejected].include? @assignation_status

          previous_status = @assignation.status
          update_assignation!
          notify_volunteer if previous_status != @assignation.status

          broadcast(:ok)
        end

        private

        # The volunteer is told either way: an accepted request means they can
        # start tracking time, and a silent rejection would leave them waiting.
        def notify_volunteer
          Decidim::EventsManager.publish(
            event: "decidim.events.time_tracker.assignation_#{@assignation_status}_event",
            event_class: EVENTS.fetch(@assignation_status),
            resource: @assignation.activity,
            affected_users: [@assignation.user]
          )
        end

        def update_assignation!
          Decidim.traceability.update!(
            @assignation,
            @user,
            status: @assignation_status
          )
        end
      end
    end
  end
end
