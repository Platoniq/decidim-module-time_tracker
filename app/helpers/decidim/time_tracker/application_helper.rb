# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Custom helpers, scoped to the time_tracker engine.
    #
    module ApplicationHelper
      include Decidim::TranslatableAttributes

      def tasks_label
        translated_attribute(component_settings.tasks_label).presence || t("models.task.name", scope: "decidim.time_tracker")
      end

      def activities_label
        translated_attribute(component_settings.activities_label).presence || t("models.activity.name", scope: "decidim.time_tracker")
      end

      def assignees_label
        translated_attribute(component_settings.assignees_label).presence || t("models.assignee.name", scope: "decidim.time_tracker")
      end

      def time_entries_label
        translated_attribute(component_settings.time_entries_label).presence || t("models.time_entry.name", scope: "decidim.time_tracker")
      end

      def milestones_label
        translated_attribute(component_settings.milestones_label).presence || t("models.milestone.name", scope: "decidim.time_tracker")
      end

      # turns a number of seconds to a string 0h 0m 0s
      def clockify_seconds(total_seconds)
        hours = total_seconds / (60 * 60)
        minutes = (total_seconds / 60) % 60
        seconds = total_seconds % 60

        "#{hours}h #{minutes}m #{seconds}s"
      end
    end
  end
end
