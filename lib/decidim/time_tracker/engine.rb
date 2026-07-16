# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module TimeTracker
    # This is the engine that runs on the public interface of time_tracker.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::TimeTracker

      routes do
        # Add engine routes here
        # resources :time_tracker
        resources :tasks do
          resources :activities do
            post :start, controller: "time_events"
            post :stop, controller: "time_events"

            resources :form, controller: "activity_questionnaire", only: [:show] do
              member do
                post :answer
                # for admin preview actions
                get :preview
                post :preview
              end
            end
          end
        end

        resource :assignee_questionnaire, controller: "assignee_questionnaire", only: [:show] do
          member do
            post :answer
            # for admin preview actions
            get :preview
            post :preview
          end
        end

        resources :milestones, only: [:create] do
          get :index, on: :collection, path: "(:nickname)"
        end

        resources :assignations, only: [:create]
        get "activities/:activity_id/assignation_status", to: "assignation_status#show", as: :activity_assignation_status

        resource :user_report, only: [:show], controller: "user_report"

        root to: "time_tracker#index"
      end

      initializer "decidim_time_tracker.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_time_tracker.add_badges" do
        Decidim::Gamification.register_badge(:time_tracker_activities) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user]

          badge.reset = lambda { |user|
            Decidim::TimeTracker::ActivityCompletion.verified
                                                    .joins(:assignation)
                                                    .where(decidim_time_tracker_assignations: { decidim_user_id: user.id })
                                                    .count
          }
        end

        Decidim::Gamification.register_badge(:time_tracker_skills) do |badge|
          badge.levels = [1, 3, 5, 10]

          badge.valid_for = [:user]

          badge.reset = lambda { |user|
            Decidim::TimeTracker::SkillCertification.where(user:).count
          }
        end
      end

      # Public naming: we surface badges/skills to participants as "Skills & badges"
      # and never expose the word "gamification" in a public URL. The core badges
      # page lives at /gamification/badges; here we serve it at the word-free
      # /badges and redirect the old path so existing links keep working.
      initializer "decidim_time_tracker.public_badges_path" do
        Decidim::Core::Engine.routes.prepend do
          # Inside the isolated Decidim namespace, controllers are referenced
          # without the leading "decidim/".
          get "/badges", to: "gamification/badges#index", as: :public_badges
          get "/gamification/badges", to: redirect("/badges")

          # Organization-level page aggregating the user's activities across
          # every time tracker component ("My voluntary work").
          get "/my_voluntary_work", to: "time_tracker/my_activities#show", as: :my_voluntary_work
        end
      end

      initializer "decidim_time_tracker.user_menu" do
        Decidim.menu :user_menu do |menu|
          menu.add_item :time_tracker,
                        I18n.t("time_tracker", scope: "layouts.decidim.user_profile"),
                        decidim.my_voluntary_work_path,
                        position: 1.4
        end
      end

      initializer "decidim.time_tracker.add_cells_view_paths" do
        # Prepend so our overrides (e.g. decidim/badges/show, which fixes the
        # "all badges" link to the word-free /badges path) take precedence over
        # the core cell templates. Our other cells are namespaced under
        # decidim/time_tracker, so no unintended core cell is shadowed.
        Cell::ViewModel.view_paths.unshift(File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/cells"))
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/views") # for partials
      end
    end
  end
end
