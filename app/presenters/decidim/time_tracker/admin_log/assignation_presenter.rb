# frozen_string_literal: true

module Decidim
  module TimeTracker
    module AdminLog
      # This class holds the logic to present a `Decidim::TimeTracker::Assignation`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    AssignationPresenter.new(action_log, view_helpers).present
      class AssignationPresenter < Decidim::Log::BasePresenter
        private

        def diff_fields_mapping
          {
            status: :string,
            decidim_user_id: :user,
            activity_id: "Decidim::TimeTracker::AdminLog::ValueTypes::ActivityPresenter",
            invited_at: :date,
            invited_by_user: :user,
            requested_at: :date,
            tos_accepted_at: :date
          }
        end

        def i18n_labels_scope
          "activemodel.attributes.time_tracker.assignation"
        end

        def action_string
          case action
          when "create", "delete", "update"
            "decidim.time_tracker.admin_log.assignation.#{action}"
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
