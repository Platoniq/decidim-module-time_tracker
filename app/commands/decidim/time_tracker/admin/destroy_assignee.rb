# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an activity
      class DestroyAssignee < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(assignee, user)
          @assignee = assignee
          @user = user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          destroy_assignee!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def destroy_assignee!
          Decidim.traceability.perform_action!(
            :delete,
            @assignee,
            @user
          ) do
            @assignee.destroy!
          end
        end
      end
    end
  end
end
