# frozen_string_literal: true

namespace :decidim_time_tracker do
  namespace :webpacker do
    desc "Installs Decidim Time Tracker webpacker files in Rails instance application"
    task install: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_time_tracker_npm
    end

    desc "Adds Decidim Time Tracker dependencies in package.json"
    task upgrade: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_time_tracker_npm
    end

    def install_time_tracker_npm
      time_tracker_npm_dependancies.each do |type, packages|
        puts "install NPM packages. You can also do this manually with this command:"
        puts "npm i --save-#{type} #{packages.join(" ")}"
        system! "npm i --save-#{type} #{packages.join(" ")}"
      end
    end

    def time_tracker_npm_dependancies
      @time_tracker_npm_dependancies ||= begin
        package_json = JSON.parse(File.read(time_tracker_path.join("package.json")))

        {
          prod: package_json["dependencies"].map { |package, version| "#{package}@#{version}" },
          dev: package_json["devDependencies"].map { |package, version| "#{package}@#{version}" }
        }.freeze
      end
    end

    def time_tracker_path
      @time_tracker_path ||= Pathname.new(time_tracker_gemspec.full_gem_path) if Gem.loaded_specs.has_key?(gem_name)
    end

    def time_tracker_gemspec
      @time_tracker_gemspec ||= Gem.loaded_specs[gem_name]
    end

    def rails_app_path
      @rails_app_path ||= Rails.root
    end

    def copy_awesome_file_to_application(origin_path, destination_path = origin_path)
      FileUtils.cp(time_tracker_path.join(origin_path), rails_app_path.join(destination_path))
    end

    def system!(command)
      system("cd #{rails_app_path} && #{command}") || abort("\n== Command #{command} failed ==")
    end

    def gem_name
      "decidim-time_tracker"
    end
  end
end
