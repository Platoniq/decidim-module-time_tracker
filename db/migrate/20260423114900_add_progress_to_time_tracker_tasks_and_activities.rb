class AddProgressToTimeTrackerTasksAndActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_time_tracker_tasks, :progress, :decimal, precision: 5, scale: 2
    add_column :decidim_time_tracker_activities, :progress, :decimal, precision: 5, scale: 2
  end
end
