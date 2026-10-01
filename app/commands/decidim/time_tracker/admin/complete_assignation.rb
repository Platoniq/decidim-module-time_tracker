# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when an admin manually adds a
      # verified completion to a user's assignation (complete: true) or
      # reverts the latest verified one (complete: false). Verified
      # completions feed the `:time_tracker_activities` badge and skill
      # certifications.
      class CompleteAssignation < Decidim::Command
        # Public: Initializes the command.
        #
        # assignation - The Assignation to update.
        # user        - The admin performing the action.
        # complete    - Boolean, whether to add a verified completion (true)
        #               or revert the latest one (false).
        def initialize(assignation, user, complete: true)
          @assignation = assignation
          @user = user
          @complete = complete
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the assignation cannot be updated.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless @assignation.accepted?
          return broadcast(:invalid) if !@complete && @assignation.completions.verified.empty?

          @complete ? add_completion! : revert_completion!
          @assignation.sync_completed_at!
          update_score!
          refresh_skill_certification!

          broadcast(:ok, @assignation)
        end

        private

        def add_completion!
          # Verifies the oldest pending completion when there is one, so a
          # manual completion does not double-count the participant's work.
          pending = @assignation.completions.pending.order(:requested_at).first

          if pending
            Decidim.traceability.update!(pending, @user, verified_at: Time.current, verified_by: @user)
          else
            Decidim.traceability.create!(
              Decidim::TimeTracker::ActivityCompletion,
              @user,
              assignation: @assignation,
              requested_at: Time.current,
              verified_at: Time.current,
              verified_by: @user
            )
          end
        end

        def revert_completion!
          completion = @assignation.completions.verified.order(:verified_at).last

          Decidim.traceability.perform_action!(:delete, completion, @user) do
            completion.destroy!
          end
        end

        def update_score!
          if @complete
            Decidim::Gamification.increment_score(@assignation.user, :time_tracker_activities)
          else
            Decidim::Gamification.decrement_score(@assignation.user, :time_tracker_activities)
          end
        end

        def refresh_skill_certification!
          SkillCertifier.new(@assignation.user, @assignation.task).refresh
        end
      end
    end
  end
end
