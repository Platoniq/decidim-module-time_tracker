# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The public "Skills & badges" explainer, served at /badges.
    #
    # It replaces Decidim's own gamification badges page, which could only
    # describe the badges registered in code at boot and so said nothing about
    # the skills and badges this organization's admins actually created. This
    # page explains both, and shows the signed-in participant where they stand.
    class BadgesController < Decidim::ApplicationController
      include Decidim::HasSpecificBreadcrumb

      helper Decidim::TimeTracker::BadgesHelper
      helper_method :badges, :skills, :platform_badges

      def index; end

      private

      # This page explains the rules; it deliberately shows nobody's personal
      # standing, so no user is passed and no per-participant metric is
      # calculated. Participants see where they are on /my_voluntary_work.
      def badges
        @badges ||= BadgeProgress.new(nil, current_organization).badges
      end

      # Every skill the organization can certify, with the tasks that grant it.
      # Skills attached to no task are left out: nothing can currently earn
      # them, so listing them would only promise participants a dead end.
      def skills
        @skills ||= Skill.where(organization: current_organization)
                         .joins(:task_skills)
                         .distinct
                         .includes(tasks: { time_tracker: :component })
                         .order(:id)
      end

      # Decidim's own badges, which are registered in code and shared by every
      # organization.
      def platform_badges
        @platform_badges ||= Decidim::Gamification.badges.sort_by(&:name)
      end

      def breadcrumb_item
        {
          label: t("decidim.time_tracker.badges.index.title"),
          active: true,
          url: decidim.public_badges_path
        }
      end
    end
  end
end
