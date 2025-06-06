# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a time entry in the Decidim::TimeTracker component.
    class TimeEvent < ApplicationRecord
      self.table_name = :decidim_time_tracker_time_events

      belongs_to :assignation,
                 class_name: "Decidim::TimeTracker::Assignation"

      belongs_to :activity,
                 class_name: "Decidim::TimeTracker::Activity"

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      # note that with the default order reversed
      # the "last" element needs to be found with .first
      default_scope { order(start: :desc) }
      scope :started_between, ->(start_date, end_date) { where("start >= ? AND start <= ?", start_date.to_i, end_date.to_i) }

      def self.last_for(user)
        if user.is_a?(Assignation)
          where(assignation: user).first
        else
          where(user:).first
        end
      end

      # number of seconds since the counting started
      # zero if activity is stopped
      def seconds_elapsed
        return 0 if stopped?
        return 0 if start.blank?

        @seconds_elapsed ||= Time.current.to_i - start.to_i
      end

      def stopped?
        stop.to_i >= start
      end

      def start_time
        Time.zone.at start
      end

      def stop_time
        Time.zone.at stop
      end

      def stop!
        self.stop = Time.current.to_i
        self.total_seconds = stop - start
        save!
      end
    end
  end
end
