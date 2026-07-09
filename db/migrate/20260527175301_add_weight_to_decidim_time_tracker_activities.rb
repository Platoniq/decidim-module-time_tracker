class AddWeightToDecidimTimeTrackerActivities < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have this column from a copy of this
  # migration that ran under a different timestamp.
  def up
    return if column_exists?(:decidim_time_tracker_activities, :weight)

    add_column :decidim_time_tracker_activities, :weight, :integer, default: 0, null: false
  end

  def down
    remove_column :decidim_time_tracker_activities, :weight if column_exists?(:decidim_time_tracker_activities, :weight)
  end
end
