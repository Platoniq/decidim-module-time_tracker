# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when updating a badge
      class UpdateBadge < Decidim::Command
        def initialize(badge, form, user)
          @badge = badge
          @form = form
          @user = user
        end

        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if form.invalid?

          update_badge!
          broadcast(:ok)
        end

        private

        attr_reader :form

        def update_badge!
          Decidim.traceability.update!(
            @badge,
            @user,
            name: form.name,
            description: form.description,
            metric: form.metric,
            levels: form.levels,
            tasks: form.tasks,
            active: form.active,
            weight: form.weight
          )
        end
      end
    end
  end
end
