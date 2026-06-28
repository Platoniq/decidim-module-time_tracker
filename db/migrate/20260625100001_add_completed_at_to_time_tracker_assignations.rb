# frozen_string_literal: true

class AddCompletedAtToTimeTrackerAssignations < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_time_tracker_assignations, :completed_at, :datetime
  end
end
