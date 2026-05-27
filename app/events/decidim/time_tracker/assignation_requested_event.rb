# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssignationRequestedEvent < Decidim::Events::SimpleEvent
      def resource_url
        EngineRouter.admin_proxy(component).task_activity_assignations_path(task, activity)
      end

      def resource_path
        EngineRouter.admin_proxy(component).task_activity_assignations_path(task, activity)
      end

      def activity
        @activity ||= resource
      end

      def task
        @task ||= activity.task
      end

      def component
        @component ||= task.time_tracker.component
      end

      def resource_title
        task.name.is_a?(Hash) ? task.name[I18n.locale.to_s] || task.name.values.first : task.name
      end
    end
  end
end
