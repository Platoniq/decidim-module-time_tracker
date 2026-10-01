# frozen_string_literal: true

class AddEarningModesAndBadgeSkills < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have these changes from a copy of this
  # migration that ran under a different timestamp.
  def up
    unless column_exists?(:decidim_time_tracker_skills, :earning_mode)
      add_column :decidim_time_tracker_skills, :earning_mode, :string, null: false, default: "completed_activities"
      # nil means every active activity of the task is required.
      add_column :decidim_time_tracker_skills, :required_activities_count, :integer
      # Only used by the time_spent mode.
      add_column :decidim_time_tracker_skills, :required_minutes, :integer
    end

    return if table_exists?(:decidim_time_tracker_badge_skills)

    create_table :decidim_time_tracker_badge_skills do |t|
      t.references :decidim_time_tracker_badge,
                   null: false,
                   index: { name: "index_tt_badge_skills_on_badge_id" },
                   foreign_key: { to_table: :decidim_time_tracker_badges }
      t.references :decidim_time_tracker_skill,
                   null: false,
                   index: { name: "index_tt_badge_skills_on_skill_id" },
                   foreign_key: { to_table: :decidim_time_tracker_skills }
      t.timestamps
    end

    add_index :decidim_time_tracker_badge_skills,
              [:decidim_time_tracker_badge_id, :decidim_time_tracker_skill_id],
              unique: true,
              name: "index_tt_badge_skills_on_badge_and_skill"
  end

  def down
    drop_table :decidim_time_tracker_badge_skills, if_exists: true
    remove_column :decidim_time_tracker_skills, :earning_mode, if_exists: true
    remove_column :decidim_time_tracker_skills, :required_activities_count, if_exists: true
    remove_column :decidim_time_tracker_skills, :required_minutes, if_exists: true
  end
end
