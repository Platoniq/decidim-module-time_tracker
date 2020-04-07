# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an task
      class UpdateTask < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(task, form, user)
          @task = task
          @form = form
          @user = user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          update_task!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def update_task!
          Decidim.traceability.update!(
            @task,
            @user,
            name: form.name
          )
        end
      end
    end
  end
end
