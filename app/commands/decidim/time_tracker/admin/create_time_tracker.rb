# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a task
      class CreateTask < Rectify::Command
        def initialize(component)
          @component = component
        end

        def call
          @time_tracker = TimeTracker.new(component: @component)

          @time_tracker.save ? broadcast(:ok) : broadcast(:invalid)
        end
      end
    end
  end
end
