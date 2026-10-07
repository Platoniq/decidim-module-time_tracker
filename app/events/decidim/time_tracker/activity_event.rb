# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Base for the notifications whose resource is an activity.
    #
    # Activities have neither a title nor a name, so Decidim's defaults would
    # leave every notification untitled; and they live under their task in the
    # routes, which the default resource locator cannot build.
    class ActivityEvent < Decidim::Events::SimpleEvent
      def resource_path
        router.task_activity_path(task, activity)
      end

      def resource_url
        router.task_activity_url(task, activity)
      end

      # The description, without the "(75%)" progress marker some
      # installations write into it (see Activity#progress).
      def resource_title
        title = decidim_sanitize_translated(activity.description).to_s.gsub(/\(\s*\d+(\.\d+)?\s*%\s*\)/, "").strip

        Decidim::ContentProcessor.render_without_format(title, links: false).html_safe
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

      # Who did it, for the admin notifications that name the volunteer.
      def participant_name
        name = (extra || {}).with_indifferent_access[:participant_name]
        name.presence || I18n.t("decidim.time_tracker.events.a_participant")
      end

      private

      # The engine is mounted once per component, so routes must be resolved
      # through the component's router or they lack the mount prefix.
      def router
        @router ||= Decidim::EngineRouter.main_proxy(component)
      end
    end
  end
end
