# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when a user creates a new milestone.
    class CreateMilestone < Rectify::Command
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

        build_attachment
        return broadcast(:invalid, form.attachment.errors) if attachment_invalid?

        transaction do
          create_milestone
          create_attachment if attachment_present?
        end

        broadcast(:ok, @milestone)
      end

      private

      attr_reader :form, :current_user, :milestone, :attachment

      def create_milestone
        @milestone = Decidim::TimeTracker::Milestone.create(
          title: form.title,
          # description: form.description,
          user: current_user,
          activity: form.activity
        )
        @attached_to = @milestone
      end
    end
  end
end
