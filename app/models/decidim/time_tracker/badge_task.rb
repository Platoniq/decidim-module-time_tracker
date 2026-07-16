# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Join record restricting a Badge to a Task. A badge with no badge_tasks
    # counts progress over every task.
    class BadgeTask < ApplicationRecord
      self.table_name = :decidim_time_tracker_badge_tasks

      belongs_to :badge,
                 foreign_key: "decidim_time_tracker_badge_id",
                 class_name: "Decidim::TimeTracker::Badge",
                 inverse_of: :badge_tasks

      belongs_to :task,
                 foreign_key: "decidim_time_tracker_task_id",
                 class_name: "Decidim::TimeTracker::Task",
                 inverse_of: :badge_tasks
    end
  end
end
