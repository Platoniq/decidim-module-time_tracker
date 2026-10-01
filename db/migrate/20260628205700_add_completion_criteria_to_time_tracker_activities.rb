class AddCompletionCriteriaToTimeTrackerActivities < ActiveRecord::Migration[6.0]
  # Guarded: consumer apps may already have these columns from a copy of this
  # migration that ran under a different timestamp.
  def up
    unless column_exists?(:decidim_time_tracker_activities, :min_events)
      add_column :decidim_time_tracker_activities, :min_events, :integer, default: 0
    end

    unless column_exists?(:decidim_time_tracker_activities, :min_duration_minutes_per_event)
      add_column :decidim_time_tracker_activities, :min_duration_minutes_per_event, :integer, default: 0
    end
  end

  def down
    remove_column :decidim_time_tracker_activities, :min_events if column_exists?(:decidim_time_tracker_activities, :min_events)
    remove_column :decidim_time_tracker_activities, :min_duration_minutes_per_event if column_exists?(:decidim_time_tracker_activities, :min_duration_minutes_per_event)
  end
end
