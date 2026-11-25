# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Public detail page of an activity: description, image, dates, progress,
    # participants and their milestones.
    class ActivitiesController < Decidim::TimeTracker::ApplicationController
      helper Decidim::TimeTracker::ApplicationHelper
      helper_method :activity, :task, :milestones

      # Authorized by Decidim::Components::BaseController (:read on the component)
      def show; end # rubocop:disable Decidim/EnforcePermissionTo

      private

      def task
        @task ||= time_tracker.tasks.find(params[:task_id])
      end

      def activity
        @activity ||= task.activities.active.find(params[:id])
      end

      # The latest milestone of each participant, like the index list.
      def milestones
        # activity is scoped to this task (task.activities)
        @milestones ||= Milestone.where(activity:) # rubocop:disable Decidim/OrganizationScopedFinder
                                 .order(Arel.sql("decidim_user_id, created_at DESC"))
                                 .select("DISTINCT ON (decidim_user_id) *")
      end
    end
  end
end
