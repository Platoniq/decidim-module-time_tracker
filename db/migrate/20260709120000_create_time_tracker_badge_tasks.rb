# frozen_string_literal: true

class CreateTimeTrackerBadgeTasks < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have this table from a copy of this
  # migration that ran under a different timestamp.
  def up
    return if table_exists?(:decidim_time_tracker_badge_tasks)

    create_table :decidim_time_tracker_badge_tasks do |t|
      t.references :decidim_time_tracker_badge,
                   null: false,
                   index: { name: "index_tt_badge_tasks_on_badge_id" },
                   foreign_key: { to_table: :decidim_time_tracker_badges }
      t.references :decidim_time_tracker_task,
                   null: false,
                   index: { name: "index_tt_badge_tasks_on_task_id" },
                   foreign_key: { to_table: :decidim_time_tracker_tasks }
      t.timestamps
    end

    add_index :decidim_time_tracker_badge_tasks,
              [:decidim_time_tracker_badge_id, :decidim_time_tracker_task_id],
              unique: true,
              name: "index_tt_badge_tasks_on_badge_and_task"
  end

  def down
    drop_table :decidim_time_tracker_badge_tasks, if_exists: true
  end
end
