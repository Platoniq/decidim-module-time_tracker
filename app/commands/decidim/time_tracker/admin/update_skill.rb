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
            tasks: form.tasks,
            earning_mode: form.earning_mode,
            required_completions_per_activity: form.required_completions_per_activity,
            required_activities_count: form.required_activities_count,
            required_minutes: form.required_minutes
          )
        end
      end
    end
  end
end
