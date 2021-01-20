# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Custom helpers, scoped to the time_tracker engine.
      #
      module ApplicationHelper

        def change_assignation_status_button(assignation, success_path: nil)
          path_reject = task_activity_assignation_path(assignation.task, assignation.activity, assignation, assignation_status: :rejected, success_path: success_path)
          path_accept = task_activity_assignation_path(assignation.task, assignation.activity, assignation, assignation_status: :accepted, success_path: success_path)
          label_reject = t("assignations.actions.reject", scope: "decidim.time_tracker.admin")
          label_accept = t("assignations.actions.accept", scope: "decidim.time_tracker.admin")

          icons = [
            assignation.pending? || assignation.accepted? ? icon_link_to("x", path_reject, label_reject, method: :patch, class: "action-icon--status") : empty_icon,
            assignation.pending? || assignation.rejected? ? icon_link_to("check", path_accept, label_accept, method: :patch, class: "action-icon--status") : empty_icon
          ]

          safe_join(icons)
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
