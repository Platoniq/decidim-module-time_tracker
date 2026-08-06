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
      helper_method :badge_progress, :skills, :platform_badges, :certified_skill_ids

      def index; end

      private

      def badge_progress
        @badge_progress ||= BadgeProgress.new(current_user, current_organization)
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

      # The skills the signed-in participant already holds, so the list can
      # mark them off.
      def certified_skill_ids
        @certified_skill_ids ||= if current_user
                                   SkillCertification.where(user: current_user)
                                                     .where.not(decidim_time_tracker_skill_id: nil)
                                                     .pluck(:decidim_time_tracker_skill_id)
                                                     .uniq
                                 else
                                   []
                                 end
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
