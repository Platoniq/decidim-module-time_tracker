class CreateDecidimTimeTrackerAssigneeData < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_assignee_data do |t|
      t.references :time_tracker, foreign_key: { to_table: :decidim_time_trackers }
      t.timestamps
    end
  end
end