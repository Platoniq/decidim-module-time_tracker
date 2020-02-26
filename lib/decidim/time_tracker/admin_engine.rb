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
        # resources :time_tracker do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "time_tracker#index"
      end

      def load_seed
        nil
      end
    end
  end
end
