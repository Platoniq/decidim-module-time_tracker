class CreateDecidimTimeTrackerAssigneeData < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_assignee_data do |t|
      t.references :decidim_time_tracker_assignee,
        foreign_key: { to_table: :decidim_time_tracker_assignees },
        index: { name: :index_decidim_time_tracker_assignee_data_assignee },
        null: false
      t.jsonb :name
      t.integer :datum_type
      t.timestamps
    end
  end
end
