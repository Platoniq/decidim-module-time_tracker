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
        if list?
          link_to milestones_path do
            content_tag :h4, class: "card__title" do
              t("title", user_name: model.user.name, scope: "decidim.time_tracker.milestone") if options[:type] == :list
            end
          end
        else
          content_tag :strong, model.title
        end
      end

      def image
        image_url = model.attachments&.first&.url

        if image_url.present?
          link_to image_url, target: :blank do
            image_tag image_url, class: "card__image"
          end
        else
          content_tag :div, class: "card__image empty" do
            icon "timer"
          end
        end
      end

      def seconds_elapsed
        @seconds_elapsed ||= model.activity.user_seconds_elapsed(model.user)
      end

      def milestones_path
        Decidim::EngineRouter.main_proxy(model.activity.task.component).milestones_path(nickname: model.user.nickname)
      end
    end
  end
end
