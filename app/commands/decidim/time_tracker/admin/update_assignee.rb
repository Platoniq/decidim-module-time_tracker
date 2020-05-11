# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an assignee
      class UpdateAssignee < Rectify::Command
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
          update_assignee!
          broadcast(:ok)
        end

        private

        def update_assignee!
          Decidim.traceability.update!(
            @assignee,
            @user,
            status: :accepted,
            invited_by_user: @user
          )
        end
      end
    end
  end
end
