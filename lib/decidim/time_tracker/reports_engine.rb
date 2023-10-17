# frozen_string_literal: true

module Decidim
  module TimeTracker
    # This is the engine that runs on the global space for `decidim-time_tracker`.
    # It handles stuff unrelated to participatory spaces or components
    # Such as user space managemt
    class ReportsEngine < ::Rails::Engine
      isolate_namespace Decidim::TimeTracker::Reports

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        authenticate(:user) do
          root to: "user#index"
        end
      end

      initializer "decidim.user_menu" do
        Decidim.menu :user_menu do |menu|
          menu.add_item :time_tracker,
                        t("time_tracker", scope: "layouts.decidim.user_profile"),
                        decidim_time_tracker.root_path,
                        position: 5.0,
                        active: :exact
        end
      end

      def load_seed
        nil
      end
    end
  end
end
