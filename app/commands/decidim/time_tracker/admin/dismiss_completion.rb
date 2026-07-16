# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # An admin dismisses a pending activity completion (the work does not
      # qualify). Verified completions cannot be dismissed; revert them
      # through CompleteAssignation instead.
      class DismissCompletion < Decidim::Command
        def initialize(completion, user)
          @completion = completion
          @user = user
        end

        # Broadcasts :ok when dismissed, :invalid otherwise.
        def call
          return broadcast(:invalid) if @completion.verified?

          dismiss!
          broadcast(:ok)
        end

        private

        def dismiss!
          Decidim.traceability.perform_action!(:delete, @completion, @user) do
            @completion.destroy!
          end
        end
      end
    end
  end
end
