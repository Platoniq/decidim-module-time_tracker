# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeEventForm < Decidim::Form
      mimic :time_event

      attribute :activity, Decidim::TimeTracker::Activity
      attribute :assignee, Decidim::TimeTracker::Assignee
      attribute :user_id, Integer
      attribute :action, String

      validates :assignee, presence: true
      validates :action, inclusion: { in: %w(start stop) }

      validate :assigned_to_activity?
      validate :activity_is_active
      validate :activity_has_started
      validate :activity_has_not_finished
      validate :user_has_time_available

      def user
        return Decidim::User.find(user_id) if user_id.present?

        assignee.user
      end

      def previous_entry
        @previous_entry ||= TimeEvent.where(activity: activity).last_for(user)
      end

      # returns number of seconds elapsed from last entry  if it is a "start"
      # returns zero otherwise
      def total_seconds
        return 0 unless previous_entry
        return 0 if previous_entry.action != "start"

        previous_entry.seconds_elapsed
      end

      private

      def assigned_to_activity?
        errors.add(:assignee, :unassigned) unless activity.assignees.find_by(id: assignee.id)
      end

      def activity_is_active
        errors.add(:activity, :inactive) unless activity.active?
      end

      def activity_has_started
        errors.add(:activity, :not_started) if activity.start_date >= Time.current
      end

      def activity_has_not_finished
        errors.add(:activity, :finished) if activity.end_date <= Time.current
      end

      def user_has_time_available
        return false unless previous_entry
        return false if previous_entry.action != action

        elapsed = previous_entry.seconds_elapsed + activity.user_total_seconds_for_date(user, Time.current)
        errors.add(:activity, :no_time_available) if elapsed >= activity.remaining_seconds_for_the_day
      end
    end
  end
end
