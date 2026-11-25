# frozen_string_literal: true

module Decidim
  module TimeTracker
    class TimeTrackerController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      helper Decidim::TimeTracker::ApplicationHelper
      helper_method :start_endpoint, :stop_endpoint, :checkout_endpoint, :checkout_survey?, :ask_data_donation?

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

      def checkout_endpoint(activity)
        Decidim::EngineRouter.main_proxy(current_component).task_activity_checkout_path(activity.task, activity.id)
      end

      # The check-out survey shows after Stop when the component turns it on.
      def checkout_survey?
        user_signed_in? && component_settings.checkout_survey_enabled
      end

      # The data donation part only until the volunteer has answered it once.
      def ask_data_donation?
        checkout_survey? && component_settings.data_donation_enabled && !DataDonation.answered_by?(current_user)
      end
    end
  end
end
