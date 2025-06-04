# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/time_tracker/version"

Gem::Specification.new do |s|
  s.version = Decidim::TimeTracker::VERSION
  s.authors = ["Ivan Vergés", "David Benabarre", "Vera Rojman"]
  s.email = ["ivan@platoniq.net"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-time_tracker"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-time_tracker"
  s.summary = "A decidim time_tracker module"
  s.description = "A tool for Decidim that allows to track time dedicated by volunteers doing any arbitrary task."

  s.files = Dir["{app,config,lib,vendor,db}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-accountability", Decidim::TimeTracker::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-admin", Decidim::TimeTracker::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-core", Decidim::TimeTracker::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-forms", Decidim::TimeTracker::COMPAT_DECIDIM_VERSION

  s.add_dependency "concurrent-ruby", "= 1.2.2"
  s.add_dependency "wicked_pdf", "~> 2.1"
  s.add_dependency "wkhtmltopdf-binary", "~> 0.12"

  s.add_development_dependency "decidim-dev", Decidim::TimeTracker::COMPAT_DECIDIM_VERSION
end
