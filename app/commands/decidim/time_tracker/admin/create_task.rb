# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a task
      class CreateTask < Decidim::Command
        def initialize(form)
          @form = form
        end

        # Creates the task if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if @form.invalid?

          create_task
          broadcast(:ok)
        end

        def create_task
          Decidim.traceability.create!(
            Decidim::TimeTracker::Task,
            @form.current_user,
            name: @form.name,
            time_tracker: @form.time_tracker
          )
        end
      end
    end
  end
end
