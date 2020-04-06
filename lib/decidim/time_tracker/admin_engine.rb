# frozen_string_literal: true

module Decidim
  module TimeTracker
    # This is the engine that runs on the public interface of `TimeTracker`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::TimeTracker::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        resources :tasks do
          resources :activities do
            resources :assignees
          end
        end
        root to: "tasks#index"
      end

      def load_seed
        nil
      end
    end
  end
end
