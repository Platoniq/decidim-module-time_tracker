# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when destroying a skill
      class DestroySkill < Decidim::Command
        def initialize(skill, user)
          @skill = skill
          @user = user
        end

        # Broadcasts :ok if successful.
        def call
          destroy_skill!
          broadcast(:ok)
        end

        private

        def destroy_skill!
          Decidim.traceability.perform_action!(:delete, @skill, @user) do
            @skill.destroy!
          end
        end
      end
    end
  end
end
