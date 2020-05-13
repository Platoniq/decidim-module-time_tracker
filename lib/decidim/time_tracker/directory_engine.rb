# frozen_string_literal: true

module Decidim
  module TimeTracker
    # This is the engine that runs on the public interface of `decidim-meetings`.
    # It mostly handles rendering the created meeting associated to a participatory
    # process.
    class DirectoryEngine < ::Rails::Engine
      isolate_namespace Decidim::TimeTracker::Directory

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        authenticate(:user) do
          resources :voluntary_work, controller: "time_tracker/voluntary_work"
        end
      end

      def load_seed
        nil
      end
    end
  end
end
