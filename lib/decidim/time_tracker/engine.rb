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
            resources :time_entries
            resources :assignees
          end
        end

        root to: "time_tracker#index"
      end

      initializer "decidim_time_tracker.assets" do |app|
        app.config.assets.precompile += %w(decidim_time_tracker_manifest.js decidim_time_tracker_manifest.css)
      end

      initializer "decidim.user_menu" do
        Decidim.menu :user_menu do |menu|
          menu.item t("voluntary_work", scope: "layouts.decidim.user_profile"),
                    decidim.voluntary_work_index_path,
                    position: 5.0,
                    active: :exact
        end
      end
    end
  end
end
