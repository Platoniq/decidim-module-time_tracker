# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeEventForm < Decidim::Form
      mimic :time_event

      attribute :activity, Decidim::TimeTracker::Activity
      attribute :assignation, Decidim::TimeTracker::Assignation
      attribute :user_id, Integer
      attribute :start, Integer
      attribute :stop, Integer

      validates :activity, presence: true
      validates :assignation, presence: true

      validate :assigned_to_activity?
      validate :activity_is_active
      validate :dates_are_valid
      validates :stop, date: { after: ->(form) { form.start } }, if: ->(form) { form.stop.present? && form.start.present? }

      def user
        return Decidim::User.find(user_id) if user_id.present?

        assignation.user
      end

      private

      def assigned_to_activity?
        errors.add(:assignation, :unassigned) unless activity.assignations.accepted.find_by(id: assignation&.id)
      end

      def activity_is_active
        errors.add(:activity, :inactive) unless activity.active?
      end

      def dates_are_valid
        [:start, :stop].each do |key|
          next unless attributes[key]

          errors.add(key, :date_format) unless attributes[key].is_a?(Time)
        end
      end
    end
  end
end
