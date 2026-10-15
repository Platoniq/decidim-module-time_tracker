# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Tells a volunteer an admin accepted their request to join an activity,
    # so they know they can start tracking time without having to check back.
    class AssignationAcceptedEvent < ActivityEvent
    end
  end
end
