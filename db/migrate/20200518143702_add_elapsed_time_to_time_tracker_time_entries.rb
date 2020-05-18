# frozen_string_literal: true

class AddElapsedTimeToTimeTrackerTimeEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_time_tracker_time_entries, :elapsed_time, :integer
  end
end
