# frozen_string_literal: true

class CreateTimeTrackerSkillCertifications < ActiveRecord::Migration[7.0]
  def change
    create_table :decidim_time_tracker_skill_certifications do |t|
      # No standalone index: the composite unique index below already covers
      # decidim_user_id as its leftmost column. (Default index name would also
      # exceed PostgreSQL's 63-char limit.)
      t.references :decidim_user, null: false, index: false
      t.references :decidim_time_tracker_task,
                   null: false,
                   index: { name: "index_tt_skill_certifications_on_task_id" },
                   foreign_key: { to_table: :decidim_time_tracker_tasks }
      t.datetime :earned_at, null: false
      t.timestamps
    end

    add_index :decidim_time_tracker_skill_certifications,
              [:decidim_user_id, :decidim_time_tracker_task_id],
              unique: true,
              name: "index_tt_skill_certifications_on_user_and_task"
  end
end
