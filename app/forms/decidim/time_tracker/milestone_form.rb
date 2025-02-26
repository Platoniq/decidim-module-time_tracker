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

      def activity
        @activity ||= Activity.find_by(id: activity_id)
      end
    end
  end
end
