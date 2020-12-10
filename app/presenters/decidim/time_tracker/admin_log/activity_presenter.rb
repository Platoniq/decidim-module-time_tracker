# frozen_string_literal: true

module Decidim
  module TimeTracker
    module AdminLog
      # This class holds the logic to present a `Decidim::TimeTracker::Activity`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    ActivityPresenter.new(action_log, view_helpers).present
      class ActivityPresenter < Decidim::Log::BasePresenter
        private

        def diff_fields_mapping
          {
            description: :i18n,
            active: :boolean
          }
        end

        def i18n_labels_scope
          "activemodel.attributes.time_tracker.activity"
        end

        def action_string
          case action
          when "create", "delete", "update"
            "decidim.time_tracker.admin_log.activity.#{action}"
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
