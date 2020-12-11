# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for an assignee in the Decidim::TimeTracker component.
    class Assignee < ApplicationRecord
      self.table_name = :decidim_time_tracker_assignees

      belongs_to :user,
                 foreign_key: "decidim_user_id",
                 class_name: "Decidim::User"

      def self.for(user)
        find_or_create_by(user: user)
      end

      def has_data?(questionnaire)
        questionnaire.answered_by?(user)
      end
    end
  end
end
