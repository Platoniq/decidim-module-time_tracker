# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Tells a space's admins that a volunteer posted an update (a milestone,
    # often with a photo) on an activity.
    class MilestoneCreatedEvent < ActivityEvent
      i18n_attributes :participant_name

      def resource_path
        router.task_activity_path(task, activity, anchor: "milestones")
      end

      def resource_url
        router.task_activity_url(task, activity, anchor: "milestones")
      end
    end
  end
end
