class CreateDecidimTimeTrackerAssigneeQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_assignee_questionnaires do |t|
      t.references :time_tracker, foreign_key: { to_table: :decidim_time_trackers }, index: { name: "index_decidim_time_tracker_assignee_questionnaires" }
      t.timestamps
    end
  end
end
