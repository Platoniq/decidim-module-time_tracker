# frozen_string_literal: true

module Decidim
  module TimeTracker
    class MilestoneForm < Decidim::Form
      mimic :milestone

      attribute :activity_id, Integer
      attribute :title, String
      attribute :description, String
      attribute :attachment, AttachmentForm

      validates :activity_id, :title, presence: true
      validates :activity, presence: true, if: ->(form) { form.activity_id.present? }
      validate :notify_missing_attachment_if_errored

      def activity
        @activity ||= Activity.find_by(id: activity_id)
      end

      private

      # This method will add an error to the `attachment` field only if there's
      # any error in any other field. This is needed because when the form has
      # an error, the attachment is lost, so we need a way to inform the user of
      # this problem.
      def notify_missing_attachment_if_errored
        errors.add(:attachment, :needs_to_be_reattached) if errors.any? && attachment.present?
      end
    end
  end
end
