# frozen_string_literal: true

class AddCompletedAtToTimeTrackerAssignations < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have this column from a copy of this
  # migration that ran under a different timestamp.
  def up
    return if column_exists?(:decidim_time_tracker_assignations, :completed_at)

    add_column :decidim_time_tracker_assignations, :completed_at, :datetime
  end

  def down
    remove_column :decidim_time_tracker_assignations, :completed_at if column_exists?(:decidim_time_tracker_assignations, :completed_at)
  end
end
