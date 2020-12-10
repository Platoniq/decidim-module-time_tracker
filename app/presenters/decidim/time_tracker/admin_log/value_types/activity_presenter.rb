# frozen_string_literal: true

module Decidim
  module TimeTracker
    module AdminLog
      module ValueTypes
        class ActivityPresenter < Decidim::Log::ValueTypes::DefaultPresenter
          # Public: Presents the value as a Decidim::TimeTracker. If the activity can
          # be found, it shows its title. Otherwise it shows its ID.
          #
          # Returns an HTML-safe String.
          def present
            return unless value
            return h.translated_attribute(activity&.description) if activity

            I18n.t("not_found", id: value, scope: "decidim.log.value_types.activity_presenter")
          end

          private

          def activity
            @activity ||= Decidim::TimeTracker::Activity.find_by(id: value)
          end
        end
      end
    end
  end
end
