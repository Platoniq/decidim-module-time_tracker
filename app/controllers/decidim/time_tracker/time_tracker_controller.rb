# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper_method :tasks, :assignee_accepted, :assignees_with_milestones, :start_endpoint, :stop_endpoint, :requests_path, :milestones_path, :questionnaire_path

      def index
        @form = form(MilestoneForm).from_params(
          attachment: form(AttachmentForm).instance
        )
      end

      private

      def tasks
        @tasks ||= Task.where(component: current_component)
      end

      def milestones
        @milestones ||= Decidim::TimeTracker::Milestone.joins(:activity).where(decidim_time_tracker_activities: { task_id: tasks.pluck(:id) })
      end

      def assignees_with_milestones
        @assignees_with_milestones ||= Assignee.select("DISTINCT ON (decidim_time_tracker_assignees.decidim_user_id) decidim_time_tracker_assignees.*")
                                               .where(status: "accepted", user: milestones.pluck(:decidim_user_id))
      end

      def start_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_start_path(activity.task, activity.id)
      end

      def stop_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_stop_path(activity.task, activity.id)
      end

      def requests_path(activity)
        Decidim::EngineRouter.main_proxy(current_component).assignees_path(activity_id: activity.id)
      end

      def milestones_path
        Decidim::EngineRouter.main_proxy(current_component).milestones_path
      end

      def questionnaire_path(activity)
        Decidim::EngineRouter.main_proxy(current_component).new_assignee_path(task_id: activity.task, activity_id: activity.id, id: activity.questionnaire.id)
      end
    end
  end
end
