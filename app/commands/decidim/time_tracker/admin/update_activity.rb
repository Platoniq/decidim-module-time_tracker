# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating an activity
      class UpdateActivity < Decidim::Command
        include Decidim::AttachmentAttributesMethods

        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(activity, form, user)
          @activity = activity
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

          update_activity!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def update_activity!
          Decidim.traceability.update!(
            @activity,
            @user,
            {
              description: @form.description,
              progress: @form.progress,
              active: @form.active,
              start_date: @form.start_date,
              end_date: @form.end_date,
              max_minutes_per_day: @form.max_minutes_per_day,
              requests_start_at: @form.requests_start_at,
              min_events: @form.min_events,
              min_duration_minutes_per_event: @form.min_duration_minutes_per_event
            }.merge(attachment_attributes(:image))
          )
        end
      end
    end
  end
end
