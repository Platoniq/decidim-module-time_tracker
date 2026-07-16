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
