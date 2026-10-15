# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # An admin verifies a pending activity completion. Verified completions
      # are what count towards the `:time_tracker_activities` badge and skill
      # certifications.
      class VerifyCompletion < Decidim::Command
        def initialize(completion, user)
          @completion = completion
          @user = user
        end

        # Broadcasts :ok when verified, :invalid otherwise.
        def call
          return broadcast(:invalid) if @completion.verified?

          verify!
          update_score!
          refresh_skill_certification!

          broadcast(:ok, @completion)
        end

        private

        def assignation
          @completion.assignation
        end

        def verify!
          Decidim.traceability.update!(
            @completion,
            @user,
            verified_at: Time.current,
            verified_by: @user
          )
          assignation.sync_completed_at!
        end

        def update_score!
          Decidim::Gamification.increment_score(assignation.user, :time_tracker_activities)
        end

        def refresh_skill_certification!
          SkillCertifier.new(assignation.user, assignation.task).refresh
        end
      end
    end
  end
end
