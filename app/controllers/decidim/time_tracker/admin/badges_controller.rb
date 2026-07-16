# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Manages the organization-wide badges participants can earn. Admins
      # define each badge's rule (metric) and level thresholds here.
      class BadgesController < Admin::ApplicationController
        helper_method :badges, :current_badge

        def index
          enforce_permission_to :index, :time_tracker_badge
        end

        def new
          enforce_permission_to :create, :time_tracker_badge

          @form = form(BadgeForm).instance
        end

        def edit
          enforce_permission_to :update, :time_tracker_badge, badge: current_badge

          @form = form(BadgeForm).from_model(current_badge)
        end

        def create
          enforce_permission_to :create, :time_tracker_badge

          @form = form(BadgeForm).from_params(params)

          CreateBadge.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("badges.create.success", scope: "decidim.time_tracker.admin")
              redirect_to skills_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("badges.create.error", scope: "decidim.time_tracker.admin")
              render :new
            end
          end
        end

        def update
          enforce_permission_to :update, :time_tracker_badge, badge: current_badge

          @form = form(BadgeForm).from_params(params)

          UpdateBadge.call(current_badge, @form, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("badges.update.success", scope: "decidim.time_tracker.admin")
              redirect_to skills_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("badges.update.error", scope: "decidim.time_tracker.admin")
              render :edit
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :time_tracker_badge, badge: current_badge

          DestroyBadge.call(current_badge, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("badges.destroy.success", scope: "decidim.time_tracker.admin")
              redirect_to skills_path
            end
          end
        end

        private

        def badges
          @badges ||= Badge.where(organization: current_organization).sorted
        end

        def current_badge
          @current_badge ||= badges.find(params[:id])
        end
      end
    end
  end
end
