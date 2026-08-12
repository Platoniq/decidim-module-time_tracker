# frozen_string_literal: true

module Decidim
  module TimeTracker
    # A global (organization-level) page listing every activity the current
    # user is assigned to, across all time tracker components. Rendered inside
    # the user profile settings layout ("My voluntary work").
    class MyActivitiesController < Decidim::ApplicationController
      include Decidim::UserProfile

      helper Decidim::ComponentPathHelper
      helper Decidim::TimeTracker::ApplicationHelper
      helper_method :assignations_by_component, :skill_certifications, :total_time

      def show; end

      private

      def assignations
        @assignations ||= Assignation.where(user: current_user)
                                     .includes(activity: { task: { time_tracker: :component } })
                                     .sorted_by_status(:accepted, :pending, :rejected)
      end

      def assignations_by_component
        @assignations_by_component ||= assignations.group_by { |assignation| assignation.task.component }
      end

      def skill_certifications
        @skill_certifications ||= SkillCertification.where(user: current_user).includes(:task).order(earned_at: :desc)
      end

      def total_time
        @total_time ||= assignations.sum(&:time_dedicated)
      end
    end
  end
end
