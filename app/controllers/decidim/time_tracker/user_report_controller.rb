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

      def show; end

      private

      def assignations
        @assignations ||= Assignation.where(user: current_user, activity: current_activities)
                                     .includes(activity: { task: { time_tracker: :component } })
                                     .sorted_by_status(:accepted, :pending, :rejected)
      end

      def skill_certifications
        @skill_certifications ||= SkillCertification.where(user: current_user, task: time_tracker.tasks)
                                                    .includes(:skill, :task)
                                                    .order(earned_at: :asc)
      end

      def current_activities
        Decidim::TimeTracker::Activity.where(task: time_tracker.tasks)
      end

      def total_time
        @total_time ||= assignations.sum(&:time_dedicated)
      end
    end
  end
end
