# frozen_string_literal: true

require "decidim/time_tracker/admin"
require "decidim/time_tracker/engine"
require "decidim/time_tracker/admin_engine"
require "decidim/time_tracker/directory"
require "decidim/time_tracker/directory_engine"
require "decidim/time_tracker/component"

module Decidim
  # This namespace holds the logic of the `TimeTracker` component. This component
  # allows users to create time_tracker in a participatory space.
  module TimeTracker
  end
end

Decidim.register_global_engine(
  :decidim_time_tracker, # this is the name of the global method to access engine routes
  ::Decidim::TimeTracker::DirectoryEngine,
  at: "/timetracker"
)
