# frozen_string_literal: true

require "decidim/dev"

require "simplecov"
SimpleCov.start "rails"
if ENV["CI"]
  require "coveralls"
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path =
  File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

require "decidim/forms/test"
require "decidim/time_tracker/test/time_tracker_context"
require "decidim/time_tracker/test/manage_questionnaires"
require "decidim/time_tracker/test/manage_questionnaire_answers"
require "decidim/time_tracker/test/update_questions"
