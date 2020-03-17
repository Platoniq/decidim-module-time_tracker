# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an task
      class DestroyTask < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(task, user)
          @task = task
          @user = user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          destroy_task!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def destroy_task!
          Decidim.traceability.perform_action!(
            :delete,
            @task,
            current_user
          ) do
            @task.destroy!
          end
        end
      end
    end
  end
end
