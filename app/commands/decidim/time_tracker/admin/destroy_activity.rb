# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an activity
      class DestroyActivity < Decidim::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(activity, user)
          @activity = activity
          @user = user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          destroy_activity!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def destroy_activity!
          Decidim.traceability.perform_action!(
            :delete,
            @activity,
            @user
          ) do
            @activity.destroy!
          end
        end
      end
    end
  end
end
