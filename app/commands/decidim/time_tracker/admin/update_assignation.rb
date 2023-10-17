# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an assignation
      class UpdateAssignation < Decidim::Command
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

          update_assignation!
          broadcast(:ok)
        end

        private

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
