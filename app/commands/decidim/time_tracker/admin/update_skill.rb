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

          affected_tasks = @skill.tasks.to_a
          update_skill!
          refresh_certifications!(affected_tasks | @skill.tasks.reload.to_a)

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

        # Changing the rules changes who qualifies, so every task the skill was
        # or is attached to has to be replayed — tasks it just lost included,
        # to revoke certifications they can no longer grant.
        def refresh_certifications!(tasks)
          tasks.each { |task| RefreshCertificationsJob.perform_later(task) }
        end
      end
    end
  end
end
