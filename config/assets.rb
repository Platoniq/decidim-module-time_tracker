# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")

Decidim::Webpacker.register_entrypoints(
  decidim_time_tracker: "#{base_path}/app/packs/entrypoints/decidim_time_tracker.js",
  decidim_time_tracker_admin: "#{base_path}/app/packs/entrypoints/decidim_time_tracker_admin.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/time_tracker/admin/time_tracker", group: :admin)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/time_tracker/time_tracker")
