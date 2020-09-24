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
        Milestone.where(user: model.user).last
      end
    end
  end
end
