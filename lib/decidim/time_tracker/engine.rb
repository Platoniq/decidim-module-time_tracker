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

            resources :form, controller: "activities_questionnaire", only: [:show] do
              member do
                post :answer
              end
            end
          end
        end
        resources :milestones, only: [:create] do
          get :index, on: :collection, path: "(:nickname)"
        end

        resources :assignees, only: [:create]

        root to: "time_tracker#index"
      end

      initializer "decidim_time_tracker.assets" do |app|
        app.config.assets.precompile += %w(decidim_time_tracker_manifest.js decidim_time_tracker_manifest.css)
      end

      initializer "decidim.time_tracker.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::TimeTracker::Engine.root}/app/views") # for partials
      end

      initializer "decidim_time_tracker.questionnaire_seeds" do |app|
        seeds = YAML.safe_load <<~YAML
          title:
            en: How do you perceive this task?
          description:
            en:
          tos:
            en: These are the Terms and Conditions. By submitting this questionnaire, you agree to them.
          questions:
            - question_type: single_option
              position: 1
              body:
                en: How important do you think this task is?
              description:
                en: From 1 to 5, do you perceive this task as most important (5), not important at all (1) or something in between?
              answer_options:
                - body:
                    en: 1 (Not important at all)
                - body:
                    en: 2 (Somewhat important)
                - body:
                    en: 3 (Quite important)
                - body:
                    en: 4 (Very important)
                - body:
                    en: 5 (Most important)
            - question_type: separator
              position: 2
              body:
                en:
              description:
                en:
            - question_type: single_option
              position: 3
              body:
                en: Who do you think usually perform this task?
              description:
                en: Do you think this task is mostly performed by people who identify with a certain gender?
              answer_options:
                - body:
                    en: Mostly women
                - body:
                    en: Mostly men
                - body:
                    en: I don't see differences by gender
                - body:
                    en: Other
                  free_text: true
        YAML

        app.config.time_tracker_questionnaire_seeds = seeds.deep_symbolize_keys
      end
    end
  end
end
