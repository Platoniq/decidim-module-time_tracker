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
          resources :activities
        end
        root to: "time_tracker#index"
      end

      initializer "decidim_time_tracker.assets" do |app|
        app.config.assets.precompile += %w(decidim_time_tracker_manifest.js decidim_time_tracker_manifest.css)
      end
    end
  end
end
