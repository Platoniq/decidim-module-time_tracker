# frozen_string_literal: true

module Decidim
  module TimeTracker
    class UserReportController < Decidim::TimeTracker::ApplicationController
      include Decidim::ComponentPathHelper

      helper Decidim::TimeTracker::ApplicationHelper
      helper_method :assignations, :total_time, :skill_certifications, :activity_path

      before_action :authenticate_user!

      def show
      end

      private

      def assignations
        Assignation.where(user: current_user, activity: current_activities).sorted_by_status(:accepted, :pending, :rejected)
      end

      def skill_certifications
        SkillCertification.where(user: current_user, task: time_tracker.tasks).includes(:task).order(earned_at: :desc)
      end

      def current_activities
        Decidim::TimeTracker::Activity.where(task: time_tracker.tasks)
      end

      def total_time
        assignations.sum(&:time_dedicated)
      end

      def activity_path(assignation)
        root_path(activity: assignation.activity)
      end
    end
  end
end
