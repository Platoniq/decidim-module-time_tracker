# frozen_string_literal: true

namespace :decidim_time_tracker do
  desc "Seeds a self-contained demo of the skills & badges system " \
       "(ORGANIZATION_HOST=… REPLACE=1 DEMO_PASSWORD=… DEMO_ADMIN_PASSWORD=…)"
  task demo_seed: :environment do
    require "decidim/time_tracker/demo_seeder"

    organization =
      if ENV["ORGANIZATION_HOST"].present?
        Decidim::Organization.find_by(host: ENV.fetch("ORGANIZATION_HOST")) ||
          abort("No organization with host #{ENV.fetch("ORGANIZATION_HOST")}")
      else
        Decidim::Organization.first
      end

    Decidim::TimeTracker::DemoSeeder.new(
      organization:,
      replace: ENV["REPLACE"].present?,
      password: ENV.fetch("DEMO_PASSWORD", nil),
      admin_password: ENV.fetch("DEMO_ADMIN_PASSWORD", nil)
    ).call
  end

  desc "Removes everything decidim_time_tracker:demo_seed created"
  task demo_unseed: :environment do
    require "decidim/time_tracker/demo_seeder"

    organization =
      if ENV["ORGANIZATION_HOST"].present?
        Decidim::Organization.find_by(host: ENV.fetch("ORGANIZATION_HOST"))
      else
        Decidim::Organization.first
      end

    Decidim::TimeTracker::DemoSeeder.new(organization:, replace: true).destroy_demo
  end
end
