# frozen_string_literal: true

class CreateTimeTrackerSkills < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have these tables from a copy of this
  # migration that ran under a different timestamp.
  def up
    unless table_exists?(:decidim_time_tracker_skills)
      create_table :decidim_time_tracker_skills do |t|
        t.jsonb :name, null: false, default: {}
        t.jsonb :description, default: {}
        t.references :decidim_organization,
                     null: false,
                     index: { name: "index_tt_skills_on_organization_id" },
                     foreign_key: { to_table: :decidim_organizations }
        t.timestamps
      end
    end

    unless table_exists?(:decidim_time_tracker_task_skills)
      create_table :decidim_time_tracker_task_skills do |t|
        t.references :decidim_time_tracker_task,
                     null: false,
                     index: { name: "index_tt_task_skills_on_task_id" },
                     foreign_key: { to_table: :decidim_time_tracker_tasks }
        t.references :decidim_time_tracker_skill,
                     null: false,
                     index: { name: "index_tt_task_skills_on_skill_id" },
                     foreign_key: { to_table: :decidim_time_tracker_skills }
        t.timestamps
      end

      add_index :decidim_time_tracker_task_skills,
                [:decidim_time_tracker_task_id, :decidim_time_tracker_skill_id],
                unique: true,
                name: "index_tt_task_skills_on_task_and_skill"
    end
  end

  def down
    drop_table :decidim_time_tracker_task_skills, if_exists: true
    drop_table :decidim_time_tracker_skills, if_exists: true
  end
end
