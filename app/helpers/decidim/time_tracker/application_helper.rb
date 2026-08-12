# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Custom helpers, scoped to the time_tracker engine.
    #
    module ApplicationHelper
      include Decidim::TranslatableAttributes

      def component_name
        (defined?(current_component) && translated_attribute(current_component&.name).presence) || t("decidim.components.time_tracker.name")
      end

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

      # Users with an accepted assignation on the activity, presented for
      # rendering with author cells. Optionally excludes a user (typically the
      # current one, so the list reads as "other people working on this").
      def activity_participants(activity, except: nil)
        users = Decidim::User.where(id: activity.assignations.accepted.select(:decidim_user_id))
        users = users.where.not(id: except.id) if except.present?
        users.map { |user| present(user) }
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
        Assignation.where(user:).sum(&:time_dedicated)
      end

      def user_joined_at(user)
        return nil if user.blank?

        Assignee.for(user).tos_accepted_at(time_tracker)
      end

      def user_last_milestone(user)
        Milestone.where(user:).order(created_at: :desc).first
      end

      def must_fill_in_data?
        return false if time_tracker.blank? || current_assignee.blank?

        !current_assignee.tos_accepted?(time_tracker) && !activities_empty?
      end

      def activities_empty?
        return true if time_tracker.blank?

        time_tracker.activities.active.empty?
      end

      # The skills a task certifies. A task with none still certifies itself,
      # using its own name — that is the module's fallback, and participants
      # should be told which of the two is happening.
      def task_skills(task)
        task.skills.to_a
      end

      # Badges that specifically name this task or one of its skills.
      #
      # Deliberately excludes badges that count across every task: those apply
      # everywhere, so repeating them under all sixteen tasks would be noise.
      # They are covered once, on the Skills & Badges page.
      def task_badges(task)
        skill_ids = task_skills(task).map(&:id)

        organization_badges.select do |badge|
          badge.badge_tasks.any? { |bt| bt.decidim_time_tracker_task_id == task.id } ||
            badge.badge_skills.any? { |bs| skill_ids.include?(bs.decidim_time_tracker_skill_id) }
        end
      end

      # Loaded once per request; task_badges is called for every task on the
      # page.
      def organization_badges
        @organization_badges ||= Decidim::TimeTracker::Badge
                                 .where(organization: current_organization)
                                 .active
                                 .sorted
                                 .includes(:badge_tasks, :badge_skills)
                                 .to_a
      end

      # How a skill is earned, in one line, for the public task list.
      def skill_earning_summary(skill)
        if skill.time_spent?
          hours = skill.required_minutes.to_i / 60.0
          hours = (hours % 1).zero? ? hours.to_i : hours.round(1)
          t("decidim.time_tracker.earnings.rules.time_spent", hours:)
        elsif skill.required_activities_count.present?
          t("decidim.time_tracker.earnings.rules.some_activities",
            activities: skill.required_activities_count, count: skill.required_completions_per_activity)
        else
          t("decidim.time_tracker.earnings.rules.all_activities", count: skill.required_completions_per_activity)
        end
      end

      def stripped_translated_attribute(attribute)
        text = translated_attribute(attribute)
        return text if text.blank?

        # Matches (75%), (75.0%), ( 75 % ), etc.
        text.gsub(/\(\s*\d+(\.\d+)?\s*%\s*\)/, "").strip
      end
    end
  end
end
