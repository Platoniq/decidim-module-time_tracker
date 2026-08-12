# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Notifies a user that they have earned a skill certification after
    # completing every active activity of a task.
    class SkillCertifiedEvent < Decidim::Events::SimpleEvent
      def resource_url
        router.user_report_url
      end

      def resource_path
        router.user_report_path
      end

      def task
        @task ||= resource
      end

      def resource_title
        task.name.is_a?(Hash) ? task.name[I18n.locale.to_s] || task.name.values.first : task.name
      end

      private

      # The engine is mounted once per component, so routes must be resolved
      # through the component's router or they lack the mount prefix.
      def router
        @router ||= Decidim::EngineRouter.main_proxy(task.component)
      end
    end
  end
end
