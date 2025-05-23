# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Activity in the Decidim::TimeTracker component. It
    # stores a description and other useful information related to an activity.
    class Activity < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_activities

      belongs_to :task,
                 class_name: "Decidim::TimeTracker::Task"

      has_many :assignations,
               class_name: "Decidim::TimeTracker::Assignation",
               dependent: :destroy

      has_many :time_events, # rubocop:disable Rails/HasManyOrHasOneDependent
               class_name: "Decidim::TimeTracker::TimeEvent"

      has_many :milestones, # rubocop:disable Rails/HasManyOrHasOneDependent
               class_name: "Decidim::TimeTracker::Milestone"

      scope :active, -> { where(active: true) }

      delegate :questionnaire, to: :task

      # total number of seconds spent by the user
      # not counting current counters
      def user_total_seconds(user)
        time_events.where(user:).sum(&:total_seconds).to_i
      end

      def user_total_seconds_for_date(user, date)
        time_events.started_between(date.beginning_of_day, date.end_of_day).where(user:).sum(&:total_seconds).to_i
      end

      # Total number of seconds spent by the user
      # and counting any possible running counters
      def user_seconds_elapsed(user)
        total = user_total_seconds(user)
        total += last_event_for(user).seconds_elapsed if last_event_for(user)
        total
      end

      def counter_active_for?(user)
        return false unless last_event_for(user)

        !last_event_for(user).stopped?
      end

      # Returns how many seconds are available for this task in the current day
      # this can be less than the activity is allowed due the change of date
      def remaining_seconds_for_today
        @remaining_seconds_for_today ||= [max_minutes_per_day * 60, (Time.current.end_of_day - Time.current).to_i].min
      end

      # how many seconds ara available for this task and user for the current day
      def user_remaining_for_date(user, date)
        total_seconds = user_total_seconds_for_date(user, date)
        remaining = max_minutes_per_day * 60
        remaining = remaining_seconds_for_today if date.beginning_of_day == Date.current

        [remaining - total_seconds, 0].max
      end

      def user_remaining_for_today(user)
        user_remaining_for_date(user, Date.current)
      end

      def assignation_pending?(user)
        assignations.pending.where(user:).count.positive?
      end

      def assignation_accepted?(user)
        assignations.accepted.where(user:).count.positive?
      end

      def assignation_rejected?(user)
        assignations.rejected.where(user:).count.positive?
      end

      def has_assignation?(user)
        assignations.where(user:).count.positive?
      end

      def has_questions?
        questionnaire.questions.any?
      end

      def allow_answers_for?(user)
        return false if status == :inactive

        return false unless has_questions?

        assignation_accepted?(user)
      end

      def answered_by?(user)
        questionnaire.answered_by? session_token(user)
      end

      # used as a unique idenfier when answering the task associated questionnaire
      def session_token(user)
        "#{Digest::SHA1.hexdigest(user.id.to_s)}-#{id}"
      end

      # Returns a identificative (I18n) string about the current status of activity
      # Returns:
      # :open if user can track time
      # :finished if current date is passed end date
      # :not_started if current date has not reach start date
      # :inactive if current status is inactive
      def status
        return :inactive unless active?
        return :not_started if start_date > Time.current.beginning_of_day
        return :finished if end_date < Time.current.beginning_of_day

        :open
      end

      def self.log_presenter_class_for(_log)
        Decidim::TimeTracker::AdminLog::ActivityPresenter
      end

      private

      def last_event_for(user)
        time_events.last_for(user)
      end
    end
  end
end
