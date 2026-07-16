# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Manages the organization-wide pool of skills that can be assigned to
      # tasks. Skills are shared by every time tracker component.
      class SkillsController < Admin::ApplicationController
        helper_method :skills, :current_skill, :badges

        def index
          enforce_permission_to :index, :skill
        end

        def new
          enforce_permission_to :create, :skill

          @form = form(SkillForm).instance
        end

        def edit
          enforce_permission_to :update, :skill, skill: current_skill

          @form = form(SkillForm).from_model(current_skill)
        end

        def create
          enforce_permission_to :create, :skill

          @form = form(SkillForm).from_params(params)

          CreateSkill.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("skills.create.success", scope: "decidim.time_tracker.admin")
              redirect_to skills_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("skills.create.error", scope: "decidim.time_tracker.admin")
              render :new
            end
          end
        end

        def update
          enforce_permission_to :update, :skill, skill: current_skill

          @form = form(SkillForm).from_params(params)

          UpdateSkill.call(current_skill, @form, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("skills.update.success", scope: "decidim.time_tracker.admin")
              redirect_to skills_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("skills.update.error", scope: "decidim.time_tracker.admin")
              render :edit
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :skill, skill: current_skill

          DestroySkill.call(current_skill, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("skills.destroy.success", scope: "decidim.time_tracker.admin")
              redirect_to skills_path
            end
          end
        end

        private

        def skills
          @skills ||= Skill.where(organization: current_organization).order(:id)
        end

        def badges
          @badges ||= Badge.where(organization: current_organization).sorted
        end

        def current_skill
          @current_skill ||= skills.find(params[:id])
        end
      end
    end
  end
end
