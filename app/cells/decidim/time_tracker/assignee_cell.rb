# frozen_string_literal: true

module Decidim
  module TimeTracker
    class AssigneeCell < Decidim::ViewModel
      include Decidim::SanitizeHelper
      include Decidim::CardHelper
      include Decidim::TimeTracker::ApplicationHelper

      view_paths << "#{Decidim::TimeTracker::Engine.root}/app/cells/decidim/time_tracker/assignee"

      def show
        render
      end

      def image
        image_url = last_milestone&.attachments&.first&.url

        if image_url.present?
          link_to image_url, target: :blank do
            image_tag image_url, class: "card__image"
          end
        else
          image_tag asset_url("decidim/time_tracker/milestone_placeholder.jpeg"), class: "card__image empty"
        end
      end

      def seconds_elapsed
        @seconds_elapsed ||= last_milestone.activity.user_seconds_elapsed(model.user)
      end

      def assignee_path
        Decidim::EngineRouter.main_proxy(model.activity.task.component).assignee_path(model)
      end

      private

      def last_milestone
        @last_milestone ||= Milestone.where(user: model.user).last
      end
    end
  end
end
