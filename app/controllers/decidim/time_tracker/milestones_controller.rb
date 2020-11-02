# frozen_string_literal: true

module Decidim
  module TimeTracker
    class MilestonesController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      # creates a milestone
      def create
        enforce_permission_to :create, :milestone, activity: activity

        @form = form(MilestoneForm).from_params(milestone_params)

        CreateMilestone.call(@form, current_user) do
          on(:ok) do |_milestone|
            flash[:notice] = I18n.t("milestones.create.success", scope: "decidim.time_tracker")
            # TODO: redirect to milestone user page
            redirect_to root_path
          end
          on(:invalid) do |_message|
            flash[:alert] = I18n.t("milestones.create.error", scope: "decidim.time_tracker")
            redirect_to root_path
          end
        end
      end

      private

      # copies the title to the attachment
      def milestone_params
        unsafe = params.to_unsafe_h
        unsafe["milestone"]["attachment"]["title"] = { I18n.locale => params[:milestone][:title] }
        unsafe
      end

      def root_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end

      def activity
        @activity ||= Activity.active.find_by(id: params[:activity_id])
      end
    end
  end
end
