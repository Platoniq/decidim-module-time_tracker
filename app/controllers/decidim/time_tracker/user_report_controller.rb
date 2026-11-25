# frozen_string_literal: true

module Decidim
  module TimeTracker
    # "My progress & skills" for one time tracker: the signed-in volunteer's
    # skills, badges and activities in this component.
    class UserReportController < Decidim::TimeTracker::ApplicationController
      include Decidim::ComponentPathHelper

      helper Decidim::TimeTracker::ApplicationHelper
      helper_method :assignations, :total_time, :skill_certifications

      before_action :authenticate_user!

      # Authorized by Decidim::Components::BaseController (:read on the component)
      def show; end # rubocop:disable Decidim/EnforcePermissionTo

      private

      def assignations
        # the current user's own records in this time tracker
        @assignations ||= Assignation.where(user: current_user, activity: current_activities) # rubocop:disable Decidim/OrganizationScopedFinder
                                     .includes(activity: { task: { time_tracker: :component } })
                                     .sorted_by_status(:accepted, :pending, :rejected)
      end

      def skill_certifications
        # the current user's own records in this time tracker
        @skill_certifications ||= SkillCertification.where(user: current_user, task: time_tracker.tasks) # rubocop:disable Decidim/OrganizationScopedFinder
                                                    .includes(:skill, :task)
                                                    .order(earned_at: :asc)
      end

      def current_activities
        # the activities of this time tracker
        Decidim::TimeTracker::Activity.where(task: time_tracker.tasks) # rubocop:disable Decidim/OrganizationScopedFinder
      end

      def total_time
        @total_time ||= assignations.sum(&:time_dedicated)
      end
    end
  end
end
