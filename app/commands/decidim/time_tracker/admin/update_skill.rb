# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating a skill
      class UpdateSkill < Decidim::Command
        def initialize(skill, form, user)
          @skill = skill
          @form = form
          @user = user
        end

        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if form.invalid?

          update_skill!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def update_skill!
          Decidim.traceability.update!(
            @skill,
            @user,
            name: form.name,
            description: form.description,
            tasks: form.tasks
          )
        end
      end
    end
  end
end
