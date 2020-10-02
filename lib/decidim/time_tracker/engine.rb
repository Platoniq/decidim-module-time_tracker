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
            resources :assignees
          end
        end
        resources :milestones

        root to: "time_tracker#index"
      end

      initializer "decidim_time_tracker.assets" do |app|
        app.config.assets.precompile += %w(decidim_time_tracker_manifest.js decidim_time_tracker_manifest.css)
      end

      initializer "decidim.time_tracker.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/views") # for partials
      end
    end
  end
end
