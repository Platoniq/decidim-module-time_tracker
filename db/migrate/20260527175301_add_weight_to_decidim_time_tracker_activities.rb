class AddWeightToDecidimTimeTrackerActivities < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_time_tracker_activities, :weight, :integer, default: 0, null: false
  end
end
