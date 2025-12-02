# frozen_string_literal: true

module Decidim
  module TimeTracker
    class MilestoneCell < Decidim::ViewModel
      include Decidim::SanitizeHelper
      include Decidim::CardHelper
      include Decidim::IconHelper
      include Decidim::TimeTracker::ApplicationHelper

      view_paths << "#{Decidim::TimeTracker::Engine.root}/app/cells/decidim/time_tracker/milestone"

      def show
        render
      end

      def list?
        options[:type] == :list
      end

      def title
        return content_tag :strong, model.title unless list?

        link_to milestones_path do
          content_tag :h3, class: "h4 text-secondary" do
            t("title", user_name: model.user.name, scope: "decidim.time_tracker.milestone")
          end
        end
      end

      def image
        image_url = model.attachments&.first&.url

        if image_url.present?
          link_to milestones_path, class: "card__link" do
            image_tag image_url, class: "card__image"
          end
        else
          content_tag :div, class: "card__image empty" do
            icon "timer-line"
          end
        end
      end

      def seconds_elapsed
        @seconds_elapsed ||= model.activity.user_seconds_elapsed(model.user)
      end

      def milestones_path
        return "#" unless model.component

        space = model.component.participatory_space
        return "#" unless space

        Decidim::EngineRouter.main_proxy(space).decidim_time_tracker_milestones_path(
          component_id: model.component.id
        )
      rescue StandardError => e
        Rails.logger.error("Error generating milestones_path: #{e.message}")
        "#"
      end
    end
  end
end
