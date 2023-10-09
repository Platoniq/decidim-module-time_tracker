# frozen_string_literal: true

module Decidim
  module TimeTracker
    class MilestonesController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory
      include Decidim::TimeTracker::ApplicationHelper

      helper_method :user, :activities

      def index
        return redirect_to root_path if user.blank?

        enforce_permission_to :index, :milestones, user: user
      end

      # creates a milestone
      def create
        enforce_permission_to :create, :milestone, activity: activity

        @form = form(MilestoneForm).from_params(milestone_params)

        CreateMilestone.call(@form, current_user) do
          on(:ok) do |_milestone|
            flash[:notice] = I18n.t("milestones.create.success", scope: "decidim.time_tracker")
            redirect_to milestones_path(nickname: current_user.nickname)
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
        unsafe["milestone"]["attachment"]["title"] = { I18n.locale => params[:milestone][:title] } if unsafe["milestone"]["attachment"].present?
        unsafe
      end

      def root_path
        Decidim::EngineRouter.main_proxy(current_component).root_path
      end

      def activity
        @activity ||= Activity.active.find_by(id: params[:milestone][:activity_id])
      end

      def activities
        @activities ||= Activity.select("DISTINCT ON (id) *")
                                .where(id: Milestone.where(user: user).select(:activity_id))
      end

      def user
        @user ||= Decidim::User.find_by(nickname: params[:nickname])
      end
    end
  end
end
