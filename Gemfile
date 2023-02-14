# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/time_tracker/version"

gem "decidim", Decidim::TimeTracker::DECIDIM_VERSION
gem "decidim-time_tracker", path: "."

gem "bootsnap", "~> 1.4"
gem "puma", ">= 5.5.1"
gem "uglifier", "~> 4.1"

group :development, :test do
  gem "byebug", ">= 11.1.3"
  gem "decidim-dev", Decidim::TimeTracker::DECIDIM_VERSION
end

group :development do
  gem "faker", "~> 2.14"
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end

group :test do
  gem "codecov", require: false
end
