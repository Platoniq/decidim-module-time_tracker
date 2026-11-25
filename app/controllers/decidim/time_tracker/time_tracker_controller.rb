# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper Decidim::TimeTracker::ApplicationHelper
      helper_method :start_endpoint, :stop_endpoint

      # Authorized by Decidim::Components::BaseController (:read on the component)
      def index # rubocop:disable Decidim/EnforcePermissionTo
        @form = form(MilestoneForm).instance
        @form.attachment = form(Decidim::AttachmentForm).instance
      end

      private

      def start_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_start_path(activity.task, activity.id)
      end

      def stop_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_stop_path(activity.task, activity.id)
      end
    end
  end
end
