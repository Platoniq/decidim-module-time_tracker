# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for an assignee in the Decidim::TimeTracker component.
    class Assignee < ApplicationRecord
      self.table_name = :decidim_time_tracker_assignees

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      has_many :tos_acceptances, # rubocop:disable Rails/HasManyOrHasOneDependent
               class_name: "Decidim::TimeTracker::TosAcceptance"

      def self.for(user)
        find_or_create_by(user:)
      end

      def tos_accepted_at(time_tracker)
        tos_acceptances.find_by(time_tracker:)&.created_at
      end

      def tos_accepted?(time_tracker)
        tos_acceptances.exists?(time_tracker:)
      end
    end
  end
end
