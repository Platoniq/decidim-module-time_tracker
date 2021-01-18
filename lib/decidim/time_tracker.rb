# frozen_string_literal: true

require "decidim/time_tracker/admin"
require "decidim/time_tracker/engine"
require "decidim/time_tracker/admin_engine"
require "decidim/time_tracker/reports"
require "decidim/time_tracker/reports_engine"
require "decidim/time_tracker/component"
module Decidim
  # This namespace holds the logic of the `TimeTracker` component. This component
  # allows users to create time_tracker in a participatory space.
  module TimeTracker
    include ActiveSupport::Configurable

    autoload :TimeTrackerActivityQuestionnaireAnswersSerializer, "decidim/time_tracker/time_tracker_activity_questionnaire_answers_serializer"

    # Returns a YAML with default seeds for activities questionnaire
    config_accessor :default_activity_questionnaire_seeds do
      YAML.load_file File.join(::Decidim::TimeTracker::Engine.root, "config", "activity_questionnaire.yml")
    end

    def self.default_activity_questionnaire
      return unless config[:default_activity_questionnaire_seeds]

      config.default_activity_questionnaire_seeds.deep_symbolize_keys
    end
    
    # Returns a YAML with default seeds for assignee data questionnaire
    config_accessor :default_assignee_questionnaire_seeds do
      YAML.load_file File.join(::Decidim::TimeTracker::Engine.root, "config", "assignee_questionnaire.yml")
    end

    def self.default_assignee_questionnaire
      return unless config[:default_assignee_questionnaire_seeds]

      config.default_assignee_questionnaire_seeds.deep_symbolize_keys
    end
  end
end

Decidim.register_global_engine(
  :decidim_time_tracker, # this is the name of the global method to access engine routes
  ::Decidim::TimeTracker::ReportsEngine,
  at: "/timetracker"
)
