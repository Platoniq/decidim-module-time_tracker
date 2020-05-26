# frozen_string_literal: true

source "https://rubygems.org"

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "decidim/time_tracker/version"

ruby RUBY_VERSION
DECIDIM_VERSION = Decidim::TimeTracker::DECIDIM_VERSION

gem "decidim", DECIDIM_VERSION
gem "decidim-time_tracker", path: "."

gem "bootsnap", "~> 1.4"
gem "puma", ">= 4.3"
gem "uglifier", "~> 4.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "faker", "~> 1.9"
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end

group :test do
  gem "codecov", require: false
end
