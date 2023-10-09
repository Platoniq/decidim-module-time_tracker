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

        root to: "time_tracker#index"
      end

      initializer "decidim_time_tracker.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim.time_tracker.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/views") # for partials
      end
    end
  end
end
