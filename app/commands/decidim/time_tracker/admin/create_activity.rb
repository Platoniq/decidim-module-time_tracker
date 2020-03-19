# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a activity
      class CreateActivity < Rectify::Command
        def initialize(form, task)
          @form = form
          @task = task
        end

        # Creates the meeting if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if @form.invalid?

          create_activity
          broadcast(:ok)
        end

        def create_activity
          Decidim.traceability.create!(
            Decidim::TimeTracker::Activity,
            @form.current_user,
            description: @form.description,
            active: @form.active,
            start_date: @form.start_date,
            end_date: @form.end_date,
            max_minutes_per_day: @form.max_minutes_per_day,
            requests_start_at: @form.requests_start_at,
            task: @task
          )
        end
      end
    end
  end
end
