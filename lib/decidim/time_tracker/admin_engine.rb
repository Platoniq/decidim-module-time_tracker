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
        get :stats, to: "stats#index"

        resources :tasks do
          resources :activities do
            resources :assignations
          end
          post "accept_all_pending_assignations", on: :collection
        end

        [:activity_questionnaire, :assignee_questionnaire].each do |questionnaire|
          resource questionnaire, controller: questionnaire, only: [:edit, :update] do
            get "/answer/:session_token", to: "#{questionnaire}#show", as: :show
            get "/answer/:session_token/export", to: "#{questionnaire}#export_response", as: :export_response
            get "/answers", to: "#{questionnaire}#index", as: :index
            get "/answer_options", to: "#{questionnaire}#answer_options", as: :answer_options
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

      initializer "decidim_time_tracker.webpacker.admin_assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
      
      def load_seed
        nil
      end
    end
  end
end
