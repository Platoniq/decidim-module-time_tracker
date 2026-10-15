# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when destroying a badge
      class DestroyBadge < Decidim::Command
        def initialize(badge, user)
          @badge = badge
          @user = user
        end

        # Broadcasts :ok if successful.
        def call
          destroy_badge!
          broadcast(:ok)
        end

        private

        def destroy_badge!
          Decidim.traceability.perform_action!(:delete, @badge, @user) do
            @badge.destroy!
          end
        end
      end
    end
  end
end
