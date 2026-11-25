# frozen_string_literal: true

module Decidim
  module TimeTracker
    # What a volunteer said about the work they just did, filled in when they
    # check out (stop the timer). One per time entry.
    class CheckoutResponse < ApplicationRecord
      self.table_name = :decidim_time_tracker_checkout_responses

      INVOLVED = %w(creating organising caring learning maintenance emotional_labour).freeze
      USUALLY_PAID = %w(yes no not_sure).freeze
      SCALE = (1..5)

      belongs_to :time_event, foreign_key: "decidim_time_tracker_time_event_id", class_name: "Decidim::TimeTracker::TimeEvent"
      belongs_to :activity, foreign_key: "decidim_time_tracker_activity_id", class_name: "Decidim::TimeTracker::Activity"
      belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"

      validates :work_nature, :work_value, inclusion: { in: SCALE }, allow_nil: true
      validates :usually_paid, inclusion: { in: USUALLY_PAID }, allow_nil: true
      validate :involved_known

      scope :for_time_tracker, lambda { |time_tracker|
        joins(activity: :task).where(decidim_time_tracker_tasks: { time_tracker_id: time_tracker.id })
      }

      private

      def involved_known
        errors.add(:involved, :inclusion) unless Array(involved).all? { |item| INVOLVED.include?(item) }
      end
    end
  end
end
