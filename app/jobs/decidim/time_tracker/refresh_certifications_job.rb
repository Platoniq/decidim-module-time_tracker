# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Re-evaluates every participant's skill certifications for a task.
    #
    # Certifications are normally reconciled as work happens — when an admin
    # verifies a completion, or when a counter stops. But an admin editing a
    # skill's rules (or attaching and detaching skills from a task) changes
    # the outcome for people who are not working right now, and until this ran
    # those changes only took effect the next time the participant happened to
    # complete something. Lowering a threshold left people uncertified, and
    # raising one left them over-certified.
    class RefreshCertificationsJob < ApplicationJob
      queue_as :default

      # task - the Task whose certifications should be recomputed.
      def perform(task)
        return if task.blank?

        Decidim::User.where(id: participant_ids(task)).find_each do |user|
          SkillCertifier.new(user, task).refresh
        end
      end

      private

      # Everyone ever assigned to one of the task's activities, plus anyone
      # already certified for it — the latter so that revocations still reach
      # participants whose assignation has since been removed.
      def participant_ids(task)
        assigned = Assignation.where(activity: task.activities).pluck(:decidim_user_id)
        certified = SkillCertification.where(task:).pluck(:decidim_user_id)

        (assigned + certified).uniq
      end
    end
  end
end
