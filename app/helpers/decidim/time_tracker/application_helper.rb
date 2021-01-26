# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Custom helpers, scoped to the time_tracker engine.
    #
    module ApplicationHelper
      include Decidim::TranslatableAttributes

      def milestones_path(params = {})
        Decidim::EngineRouter.main_proxy(current_component).milestones_path(params)
      end

      def tasks_label
        translated_attribute(component_settings.tasks_label).presence || t("models.task.name", scope: "decidim.time_tracker")
      end

      def activities_label
        translated_attribute(component_settings.activities_label).presence || t("models.activity.name", scope: "decidim.time_tracker")
      end

      def assignations_label
        translated_attribute(component_settings.assignations_label).presence || t("models.assignation.name", scope: "decidim.time_tracker")
      end

      def time_events_label
        translated_attribute(component_settings.time_events_label).presence || t("models.time_entry.name", scope: "decidim.time_tracker")
      end

      def milestones_label
        translated_attribute(component_settings.milestones_label).presence || t("models.milestone.name", scope: "decidim.time_tracker")
      end

      # turns a number of seconds to a string 0h 0m 0s
      def clockify_seconds(total_seconds, padded: false)
        total_seconds = total_seconds.to_i

        clock = {
          hours: total_seconds / (60 * 60),
          minutes: (total_seconds / 60) % 60,
          seconds: total_seconds % 60
        }

        content_tag :span, class: "time-tracker--clock" do
          safe_join(
            clock.map do |label, value|
              string_value = padded ? value.to_s.rjust(2, "0") : value
              content_tag(:span, t("decidim.time_tracker.clock.#{label}", n: string_value), class: ("text-muted" if value.zero?))
            end
          )
        end
      end

      def assignation_status_label(status)
        klass = case status
                when "accepted" then "success"
                when "pending" then "warning"
                when "rejected" then "danger"
                end

        content_tag :span, class: "#{klass} label" do
          t("models.assignation.fields.statuses.#{status}", scope: "decidim.time_tracker")
        end
      end

      def assignation_date(assignation)
        if assignation.invited_at.present?
          t("models.assignation.fields.invited_at", time: l(assignation.invited_at, format: :short), scope: "decidim.time_tracker")
        elsif assignation.requested_at.present?
          t("models.assignation.fields.requested_at", time: l(assignation.requested_at, format: :short), scope: "decidim.time_tracker")
        end
      end

      def user_total_time_dedicated(user)
        Assignation.where(user: user).sum(&:time_dedicated)
      end

      def user_joined_at
        current_assignee.tos_accepted_at(time_tracker)
      end

      def user_last_milestone(user)
        Milestone.where(user: user).order(created_at: :desc).first
      end

      def must_fill_in_data?
        !current_assignee.tos_accepted?(time_tracker) && !activities_empty?
      end

      def activities_empty?
        time_tracker.activities.active.empty?
      end
    end
  end
end
