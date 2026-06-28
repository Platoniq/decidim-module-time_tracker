# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when an admin marks (or unmarks) a
      # user's assignation to an activity as completed. Completing an assignation
      # awards the generic `:time_tracker_activities` badge and may certify the
      # related task's skill once all its activities are completed.
      class CompleteAssignation < Decidim::Command
        # Public: Initializes the command.
        #
        # assignation - The Assignation to update.
        # user        - The admin performing the action.
        # complete    - Boolean, whether to mark as completed (true) or revert (false).
        def initialize(assignation, user, complete: true)
          @assignation = assignation
          @user = user
          @complete = complete
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the assignation cannot be completed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless @assignation.accepted?
          return broadcast(:invalid) if @complete == @assignation.completed?

          update_assignation!
          update_score!
          refresh_skill_certification!

          broadcast(:ok, @assignation)
        end

        private

        def update_assignation!
          Decidim.traceability.update!(
            @assignation,
            @user,
            completed_at: @complete ? Time.current : nil
          )
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
