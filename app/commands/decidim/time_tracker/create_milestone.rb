# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A command with all the business logic when a user creates a new milestone.
    class CreateMilestone < Rectify::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the milestone.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        # return broadcast(:invalid) if form.invalid?

        build_attachment
        return broadcast(:invalid) if attachment_invalid?

        transaction do
          create_milestone
          create_attachment
        end

        broadcast(:ok, @milestone)
      end

      private

      attr_reader :form, :milestone, :attachment

      def attachment_invalid?
        if attachment.invalid? && attachment.errors.has_key?(:file)
          @form.attachment.errors.add :file, attachment.errors[:file]
          true
        end
      end

      def create_attachment
        attachment.attached_to = @attached_to
        attachment.save!
      end

      def build_attachment
        @attachment = Attachment.new(
          title: @form.title,
          file: @form.file,
          attached_to: @attached_to
        )
      end

      def create_milestone
        @milestone = Decidim::TimeTracker::Milestone.create(
          title: form.title,
          user: current_user,
          component: current_component
        )
        @attached_to = @milestone
      end
    end
  end
end
