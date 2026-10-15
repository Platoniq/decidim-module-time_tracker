# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Tells a space's admins that a volunteer's tracked time met an activity's
    # rule and a completion is waiting for them to verify it.
    class CompletionRequestedEvent < ActivityEvent
      i18n_attributes :participant_name

      def resource_path
        Decidim::EngineRouter.admin_proxy(component).tasks_path
      end

      def resource_url
        Decidim::EngineRouter.admin_proxy(component).tasks_url
      end
    end
  end
end
