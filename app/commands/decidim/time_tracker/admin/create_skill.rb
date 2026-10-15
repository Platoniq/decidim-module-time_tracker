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

          skill = create_skill
          # Participants may already satisfy the new skill with work they did
          # before it existed; certify them now instead of waiting for their
          # next verified completion.
          skill.tasks.each { |task| RefreshCertificationsJob.perform_later(task) }

          broadcast(:ok)
        end

        def create_skill
          Decidim.traceability.create!(
            Decidim::TimeTracker::Skill,
            @form.current_user,
            name: @form.name,
            description: @form.description,
            tasks: @form.tasks,
            earning_mode: @form.earning_mode,
            required_completions_per_activity: @form.required_completions_per_activity,
            required_activities_count: @form.required_activities_count,
            required_minutes: @form.required_minutes,
            organization: @form.current_organization
          )
        end
      end
    end
  end
end
