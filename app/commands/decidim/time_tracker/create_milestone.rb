# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when a user creates a new milestone.
    class CreateMilestone < Decidim::Command
      include ::Decidim::AttachmentMethods
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form, current_user)
        @form = form
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the milestone.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid, form.errors) if form.invalid?

        if attachment_present?
          build_attachment
          return broadcast(:invalid, form.attachment.errors) if attachment_invalid?
        end

        transaction do
          create_milestone!
          create_attachment if attachment_present?
        end
        notify_admins

        broadcast(:ok, @milestone)
      end

      private

      attr_reader :form, :current_user, :milestone, :attachment

      def create_milestone!
        @milestone = Decidim::TimeTracker::Milestone.create!(
          title: form.title,
          description: form.description,
          user: current_user,
          activity: form.activity
        )
        @attached_to = @milestone
      end

      # Updates are often the proof an admin looks at before verifying, so
      # they are emailed whatever the admin's digest setting.
      def notify_admins
        activity = @milestone.activity
        Decidim::EventsManager.publish(
          event: "decidim.events.time_tracker.milestone_created_event",
          event_class: Decidim::TimeTracker::MilestoneCreatedEvent,
          resource: activity,
          followers: activity.task.component.participatory_space.admins,
          extra: { participant_name: current_user.name, force_email: true }
        )
      end

      def attachment_present?
        @form.attachment && @form.attachment.file.present?
      end
    end
  end
end
