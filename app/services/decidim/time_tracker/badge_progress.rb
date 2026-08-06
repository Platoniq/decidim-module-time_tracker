# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Where a participant stands on every active badge of an organization.
    #
    # This is the read model behind both the "My badges" section and the
    # public explainer page, so the rules for reading a badge live here rather
    # than being spelled out again in each template. Pass a nil user (an
    # anonymous visitor on the explainer page) to get every badge at zero
    # without touching the database.
    class BadgeProgress
      # One badge as seen by one participant.
      Status = Struct.new(:badge, :value, :level, :next_threshold) do
        def earned?
          level.positive?
        end

        def maxed?
          next_threshold.nil?
        end

        # How far along the current level is, as a 0-100 integer.
        def percent
          return 100 if maxed?
          return 0 unless next_threshold.positive?

          [value * 100 / next_threshold, 100].min
        end
      end

      def initialize(user, organization)
        @user = user
        @organization = organization
      end

      delegate :any?, to: :badges

      def statuses
        @statuses ||= badges.map { |badge| status_for(badge) }
      end

      # Only the badges the participant has actually reached level 1 on.
      def earned
        statuses.select(&:earned?)
      end

      def badges
        @badges ||= Badge.where(organization: @organization)
                         .active
                         .sorted
                         .includes(:badge_tasks, :badge_skills, :tasks, :skills)
      end

      private

      attr_reader :user

      def metrics
        @metrics ||= BadgeMetrics.new(user)
      end

      def status_for(badge)
        value = value_for(badge)

        Status.new(badge, value, badge.level_for(value), badge.next_level_threshold(value))
      end

      def value_for(badge)
        return 0 if user.blank?

        metrics.value_for(
          badge.metric,
          task_ids: badge.badge_tasks.map(&:decidim_time_tracker_task_id),
          skill_ids: badge.badge_skills.map(&:decidim_time_tracker_skill_id)
        )
      end
    end
  end
end
