class AddCompletionCriteriaToTimeTrackerActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_time_tracker_activities, :min_events, :integer, default: 0
    add_column :decidim_time_tracker_activities, :min_duration_minutes_per_event, :integer, default: 0
  end
end
