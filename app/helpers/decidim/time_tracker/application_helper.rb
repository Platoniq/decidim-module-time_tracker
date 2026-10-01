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

      # "1 Aug – 1 Dec 2026". The year is written once unless the range
      # crosses into another one.
      def date_range(start_at, end_at)
        first, last = [start_at, end_at].map { |time| time&.to_date }
        dates = [first, last].compact.uniq
        return if dates.empty?
        return l(dates.first, format: :decidim_short_with_month_name_short) if dates.one?

        opening = l(first, format: first.year == last.year ? :decidim_with_month_name_short : :decidim_short_with_month_name_short)
        "#{opening} – #{l(last, format: :decidim_short_with_month_name_short)}"
      end

      # "2 h 15 min" — a duration to read, as opposed to the running clock.
      def duration_in_words(seconds)
        hours, minutes = (seconds.to_i / 60.0).round.divmod(60)
        return t("decidim.time_tracker.duration.minutes", count: minutes) if hours.zero?
        return t("decidim.time_tracker.duration.hours", count: hours) if minutes.zero?

        t("decidim.time_tracker.duration.hours_minutes", hours:, minutes:)
      end

      # "2:15:07", the face of a running timer. The script that ticks it
      # formats seconds the same way.
      def timer_clock(seconds)
        seconds = seconds.to_i
        format("%<hours>d:%<minutes>02d:%<seconds>02d", hours: seconds / 3600, minutes: (seconds / 60) % 60, seconds: seconds % 60)
      end

      # The one status every activity shows: whether its timer can run now.
      def activity_status_label(activity)
        status = activity.status
        text = if status == :not_started && activity.start_date.present?
                 t("decidim.time_tracker.activity_status.starts_on", date: l(activity.start_date.to_date, format: :decidim_with_month_name_short))
               else
                 t("decidim.time_tracker.activity_status.#{status}")
               end

        content_tag(:span, text, class: "time-tracker__status-label time-tracker__status-label--#{status}")
      end

      # What a volunteer has to do for their work on an activity to be
      # submitted for verification, or nil when it has no completion rule.
      def completion_rule_sentence(activity)
        return if activity.min_events.to_i <= 0 || activity.min_duration_minutes_per_event.to_i <= 0

        t("decidim.time_tracker.completion_rule.sessions",
          count: activity.min_events,
          duration: duration_in_words(activity.min_duration_minutes_per_event.to_i * 60))
      end

      def daily_limit_sentence(activity)
        return if activity.max_minutes_per_day.to_i <= 0

        t("decidim.time_tracker.completion_rule.daily_limit", duration: duration_in_words(activity.max_minutes_per_day.to_i * 60))
      end

      # A row of overlapping avatars, for "who works on this".
      def participant_avatars(users, limit: 4)
        return if users.blank?

        content_tag :span, class: "time-tracker__avatars" do
          avatars = users.first(limit).map do |user|
            presented = present(user)
            image_tag(presented.avatar_url, alt: "", title: presented.name, class: "time-tracker__avatar", loading: "lazy")
          end
          avatars << content_tag(:span, "+#{users.size - limit}", class: "time-tracker__avatar time-tracker__avatar--more") if users.size > limit
          safe_join(avatars)
        end
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
                when "rejected" then "alert"
                end

        content_tag :span, class: "#{klass} label" do
          t("models.assignation.fields.statuses.#{status}", scope: "decidim.time_tracker")
        end
      end

      # When someone was added to an activity, or asked to join it. The
      # "invited at" string this used to borrow is a column header with no
      # place for the date, so every activity read "Invited at" and nothing else.
      def assignation_date(assignation)
        if assignation.invited_at.present?
          t("decidim.time_tracker.assignation_dates.invited", date: l(assignation.invited_at.to_date, format: :decidim_short_with_month_name_short))
        elsif assignation.requested_at.present?
          t("decidim.time_tracker.assignation_dates.requested", date: l(assignation.requested_at.to_date, format: :decidim_short_with_month_name_short))
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
