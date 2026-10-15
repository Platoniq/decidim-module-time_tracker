# frozen_string_literal: true

class CreateTimeTrackerActivityCompletions < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have this table from a copy of this
  # migration that ran under a different timestamp.
  def up
    return if table_exists?(:decidim_time_tracker_activity_completions)

    create_table :decidim_time_tracker_activity_completions do |t|
      t.references :decidim_time_tracker_assignation,
                   null: false,
                   index: { name: "index_tt_completions_on_assignation_id" },
                   foreign_key: { to_table: :decidim_time_tracker_assignations }
      t.datetime :requested_at, null: false
      t.datetime :verified_at
      t.references :verified_by,
                   index: { name: "index_tt_completions_on_verified_by_id" },
                   foreign_key: { to_table: :decidim_users }
      t.timestamps
    end

    # Assignations completed under the old boolean model become a single
    # verified completion so nobody loses earned badges or skills.
    execute <<~SQL.squish
      INSERT INTO decidim_time_tracker_activity_completions
        (decidim_time_tracker_assignation_id, requested_at, verified_at, created_at, updated_at)
      SELECT id, completed_at, completed_at, NOW(), NOW()
      FROM decidim_time_tracker_assignations
      WHERE completed_at IS NOT NULL
    SQL
  end

  def down
    drop_table :decidim_time_tracker_activity_completions, if_exists: true
  end
end
