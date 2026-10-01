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
      scope :started_between, ->(start_date, end_date) { where(start: start_date.to_i..end_date.to_i) }

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
        return true if start.blank?

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

        check_completion_criteria!
        refresh_time_based_skills!
      end

      private

      # Meeting the activity's completion criteria no longer completes the
      # assignation directly: it files a pending completion that an admin has
      # to verify before it counts towards badges and skills. Every further
      # batch of `min_events` qualifying sessions files another one.
      def check_completion_criteria!
        min_events = activity.min_events
        min_duration = activity.min_duration_minutes_per_event
        return if min_events.blank? || min_events <= 0
        return if min_duration.blank? || min_duration <= 0

        qualifying_events = activity.time_events
                                    .where(user:)
                                    .where(total_seconds: (min_duration * 60)..)
                                    .count

        achievable = qualifying_events / min_events
        recorded = assignation.completions.count
        assignation.completions.create!(requested_at: Time.current) if achievable > recorded
      end

      # Time-based skills certify from tracked time directly, so they must
      # be re-evaluated whenever a counter stops.
      def refresh_time_based_skills!
        task = activity.task
        return unless task.skills.where(earning_mode: "time_spent").any?

        Decidim::TimeTracker::SkillCertifier.new(user, task).refresh
      end
    end
  end
end
