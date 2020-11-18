# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an activity
      class DestroyAssignation < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(assignation, user)
          @assignation = assignation
          @user = user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          destroy_assignation!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def destroy_assignation!
          Decidim.traceability.perform_action!(
            :delete,
            @assignation,
            @user
          ) do
            @assignation.destroy!
          end
        end
      end
    end
  end
end
