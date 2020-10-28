# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an assignee
      class UpdateAssignee < Rectify::Command
        # Public: Initializes the command.
        #
        # assignee_status - A symbol representing the assignee status.
        def initialize(assignee, user, assignee_status)
          @assignee = assignee
          @user = user
          @assignee_status = assignee_status
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless [:accepted, :rejected].include? @assignee_status

          update_assignee!
          broadcast(:ok)
        end

        private

        def update_assignee!
          Decidim.traceability.update!(
            @assignee,
            @user,
            invited_by_user: @user, # TODO: Why?
            status: @assignee_status
          )
        end
      end
    end
  end
end
