# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Tells the space's admins that someone asked to join an activity, and
    # links them to where the request is accepted.
    class AssignationRequestedEvent < ActivityEvent
      def resource_path
        Decidim::EngineRouter.admin_proxy(component).task_activity_assignations_path(task, activity)
      end

      def resource_url
        Decidim::EngineRouter.admin_proxy(component).task_activity_assignations_url(task, activity)
      end
    end
  end
end
