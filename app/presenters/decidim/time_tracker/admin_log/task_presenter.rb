# frozen_string_literal: true

module Decidim
  module TimeTracker
    module AdminLog
      # This class holds the logic to present a `Decidim::TimeTracker::Task`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    TaskPresenter.new(action_log, view_helpers).present
      class TaskPresenter < Decidim::Log::BasePresenter
        private

        def diff_fields_mapping
          {
            name: :i18n,
            time_tracker_id: "Decidim::TimeTracker::AdminLog::ValueTypes::TimeTrackerPresenter",
            active: :boolean,
            updated_at: :date
          }
        end

        def i18n_labels_scope
          "activemodel.attributes.time_tracker.task"
        end

        def action_string
          case action
          when "create", "delete", "update"
            "decidim.time_tracker.admin_log.task.#{action}"
          else
            super
          end
        end

        def has_diff?
          action == "delete" || super
        end
      end
    end
  end
end
