# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a badge
      class CreateBadge < Decidim::Command
        def initialize(form)
          @form = form
        end

        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if @form.invalid?

          create_badge
          broadcast(:ok)
        end

        def create_badge
          Decidim.traceability.create!(
            Decidim::TimeTracker::Badge,
            @form.current_user,
            name: @form.name,
            description: @form.description,
            metric: @form.metric,
            levels: @form.levels,
            tasks: @form.tasks,
            skills: @form.skills,
            active: @form.active,
            weight: @form.weight,
            organization: @form.current_organization
          )
        end
      end
    end
  end
end
