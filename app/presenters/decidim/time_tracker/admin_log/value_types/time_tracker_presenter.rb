# frozen_string_literal: true

module Decidim
  module TimeTracker
    module AdminLog
      module ValueTypes
        class TimeTrackerPresenter < Decidim::Log::ValueTypes::DefaultPresenter
          # Public: Presents the value as a Decidim::TimeTracker. If the time_tracker can
          # be found, it shows its title. Otherwise it shows its ID.
          #
          # Returns an HTML-safe String.
          def present
            return unless value
            return h.translated_attribute(time_tracker&.component&.name) if time_tracker

            I18n.t("not_found", id: value, scope: "decidim.log.value_types.time_tracker_presenter")
          end

          private

          def time_tracker
            @time_tracker ||= Decidim::TimeTracker::TimeTracker.find_by(id: value)
          end
        end
      end
    end
  end
end
