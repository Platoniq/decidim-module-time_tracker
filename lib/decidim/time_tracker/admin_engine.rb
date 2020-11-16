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

        [:questionnaire, :assignee_questionnaire].each do |questionnaire_resource|
          resource questionnaire_resource, only: [:edit, :update] do
            get "/answer_options", to: "#{questionnaire_resource}#answer_options", as: :answer_options
          end
        end

        get :time_tracker_exports, to: "time_tracker_exports#export"
        # resource :time_tracker_exports, shallow: false do
        #   collection do
        #     get :export
        #   end
        # end

        root to: "tasks#index"
      end

      initializer "decidim_time_tracker.admin_assets" do |app|
        app.config.assets.precompile += %w(admin/decidim_time_tracker_manifest.js admin/decidim_time_tracker_manifest.css)
      end

      def load_seed
        nil
      end
    end
  end
end
