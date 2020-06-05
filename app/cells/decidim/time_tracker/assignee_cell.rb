# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeCell < Decidim::ViewModel
      include Decidim::SanitizeHelper
      include Decidim::CardHelper

      view_paths << "#{Decidim::TimeTracker::Engine.root}/app/cells/decidim/time_tracker/assignee"

      def show
        render
      end

      private

      def last_milestone
        model.time_entries.last&.milestone
      end
    end
  end
end
