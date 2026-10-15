# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Custom helpers, scoped to the time_tracker engine.
      #
      module ApplicationHelper
        def change_assignation_status_button(assignation, success_path: nil)
          path_reject = task_activity_assignation_path(assignation.task, assignation.activity, assignation, assignation_status: :rejected, success_path:)
          path_accept = task_activity_assignation_path(assignation.task, assignation.activity, assignation, assignation_status: :accepted, success_path:)
          label_reject = t("assignations.actions.reject", scope: "decidim.time_tracker.admin")
          label_accept = t("assignations.actions.accept", scope: "decidim.time_tracker.admin")

          icons = [
            assignation.pending? || assignation.accepted? ? icon_link_to("close-line", path_reject, label_reject, method: :patch, class: "action-icon--status") : empty_icon,
            assignation.pending? || assignation.rejected? ? icon_link_to("check-line", path_accept, label_accept, method: :patch, class: "action-icon--status") : empty_icon
          ]

          safe_join(icons)
        end

        # Add a verified completion, and revert the latest one when there is
        # any. With per-activity repetition rules an assignation can hold any
        # number of verified completions.
        def complete_assignation_button(assignation, success_path: nil)
          return unless assignation.accepted?

          add_path = complete_task_activity_assignation_path(assignation.task, assignation.activity, assignation, success_path:)
          revert_path = complete_task_activity_assignation_path(assignation.task, assignation.activity, assignation, success_path:, revert: true)

          icons = [
            icon_link_to(
              "check-double-line",
              add_path,
              t("assignations.actions.complete", scope: "decidim.time_tracker.admin"),
              method: :patch,
              class: "action-icon--complete"
            )
          ]

          if assignation.verified_completions_count.positive?
            icons << icon_link_to(
              "arrow-go-back-line",
              revert_path,
              t("assignations.actions.uncomplete", scope: "decidim.time_tracker.admin"),
              method: :patch,
              class: "action-icon--completed"
            )
          end

          safe_join(icons)
        end

        # Verify or dismiss the oldest pending completion of an assignation.
        def pending_completion_buttons(assignation, success_path: nil)
          completion = assignation.pending_completions.order(:requested_at).first
          return if completion.blank?

          safe_join(
            [
              icon_link_to(
                "checkbox-circle-line",
                verify_task_activity_assignation_completion_path(assignation.task, assignation.activity, assignation, completion, success_path:),
                t("completions.actions.verify", scope: "decidim.time_tracker.admin"),
                method: :patch,
                class: "action-icon--complete"
              ),
              icon_link_to(
                "close-circle-line",
                dismiss_task_activity_assignation_completion_path(assignation.task, assignation.activity, assignation, completion, success_path:),
                t("completions.actions.dismiss", scope: "decidim.time_tracker.admin"),
                method: :delete,
                class: "action-icon--remove",
                data: { confirm: t("completions.actions.confirm_dismiss", scope: "decidim.time_tracker.admin") }
              )
            ]
          )
        end

        # The plain-words unit for a badge metric ("hours tracked"), shown next
        # to each level threshold.
        #
        # Guarded against a blank metric: "units.#{nil}" resolves to the parent
        # `units` node, and I18n happily returns that whole hash, which then
        # renders as a Ruby hash literal beside every level on the new-badge
        # form.
        def badge_metric_unit(metric)
          return "" if metric.blank?

          unit = t("badges.form.units.#{metric}", scope: "decidim.time_tracker.admin", default: "")
          unit.is_a?(String) ? unit : ""
        end

        # The same labels keyed by metric, for the admin script to swap between
        # when the rule changes.
        def badge_metric_units_json
          Decidim::TimeTracker::Badge::METRICS.index_with { |metric| badge_metric_unit(metric) }.to_json
        end

        # Metric names in plain words, for the live rule preview.
        def badge_metric_labels_json
          Decidim::TimeTracker::Badge::METRICS
            .index_with { |metric| t("models.badge.metrics.#{metric}", scope: "decidim.time_tracker") }
            .to_json
        end

        # Sentence templates the badge script fills in as fields change, so an
        # admin reads the rule they are building rather than inferring it.
        def badge_preview_templates_json
          {
            required_skills: t("badges.form.preview.required_skills", scope: "decidim.time_tracker.admin"),
            restricted: t("badges.form.preview.restricted", scope: "decidim.time_tracker.admin"),
            all_tasks: t("badges.form.preview.all_tasks", scope: "decidim.time_tracker.admin"),
            levels: t("badges.form.preview.levels", scope: "decidim.time_tracker.admin"),
            no_skills: t("badges.form.preview.no_skills", scope: "decidim.time_tracker.admin")
          }.to_json
        end

        # The same for the skill form.
        def skill_rule_strings_json
          scope = "decidim.time_tracker.admin.skills.form.preview"
          {
            time_spent: t("time_spent", scope:),
            all_one: t("all_one", scope:),
            all_other: t("all_other", scope:),
            some_one: t("some_one", scope:),
            some_other: t("some_other", scope:),
            incomplete: t("incomplete", scope:)
          }.to_json
        end

        def empty_icon
          content_tag :a, class: "action-icon" do
            content_tag :span do
              icon("", aria_label: "", role: "img")
            end
          end
        end
      end
    end
  end
end
