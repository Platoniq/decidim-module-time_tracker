# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Custom helpers, scoped to the time_tracker engine.
      #
      module ApplicationHelper
        def change_assignee_status_button(assignee)
          path_reject = task_activity_assignee_path(current_task, current_activity, assignee, assignee_status: :rejected)
          path_accept = task_activity_assignee_path(current_task, current_activity, assignee, assignee_status: :accepted)
          label_reject = t("actions.reject", scope: "decidim.time_tracker")
          label_accept = t("actions.accept", scope: "decidim.time_tracker")

          icons = [
            assignee.pending? || assignee.accepted? ? icon_link_to("x", path_reject, label_reject, method: :patch, class: "action-icon--status") : empty_icon,
            assignee.pending? || assignee.rejected? ? icon_link_to("check", path_accept, label_accept, method: :patch, class: "action-icon--status") : empty_icon
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
