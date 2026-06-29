# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Notifies a user that they have earned a skill certification after
    # completing every active activity of a task.
    class SkillCertifiedEvent < Decidim::Events::SimpleEvent
      def resource_url
        report_path
      end

      def resource_path
        report_path
      end

      def task
        @task ||= resource
      end

      def resource_title
        task.name.is_a?(Hash) ? task.name[I18n.locale.to_s] || task.name.values.first : task.name
      end

      private

      def report_path
        Decidim::TimeTracker::Engine.routes.url_helpers.user_report_path
      end
    end
  end
end
