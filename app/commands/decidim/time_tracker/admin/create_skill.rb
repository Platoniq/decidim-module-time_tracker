# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a skill
      class CreateSkill < Decidim::Command
        def initialize(form)
          @form = form
        end

        # Creates the skill if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if @form.invalid?

          create_skill
          broadcast(:ok)
        end

        def create_skill
          Decidim.traceability.create!(
            Decidim::TimeTracker::Skill,
            @form.current_user,
            name: @form.name,
            description: @form.description,
            organization: @form.current_organization
          )
        end
      end
    end
  end
end
