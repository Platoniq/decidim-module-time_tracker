# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a activity
      class CreateActivity < Decidim::Command
        def initialize(form, task)
          @form = form
          @task = task
        end

        # Creates the activity if valid.
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
            progress: @form.progress,
            active: @form.active,
            start_date: @form.start_date,
            end_date: @form.end_date,
            max_minutes_per_day: @form.max_minutes_per_day,
            requests_start_at: @form.requests_start_at,
            min_events: @form.min_events,
            min_duration_minutes_per_event: @form.min_duration_minutes_per_event,
            task: @task
          )
        end
      end
    end
  end
end
