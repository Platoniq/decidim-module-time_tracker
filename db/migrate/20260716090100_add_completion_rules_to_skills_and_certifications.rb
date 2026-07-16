# frozen_string_literal: true

class AddCompletionRulesToSkillsAndCertifications < ActiveRecord::Migration[7.0]
  # Guarded: consumer apps may already have these changes from a copy of this
  # migration that ran under a different timestamp.
  def up
    unless column_exists?(:decidim_time_tracker_skills, :required_completions_per_activity)
      add_column :decidim_time_tracker_skills, :required_completions_per_activity, :integer, null: false, default: 1
    end

    return if column_exists?(:decidim_time_tracker_skill_certifications, :decidim_time_tracker_skill_id)

    add_reference :decidim_time_tracker_skill_certifications, :decidim_time_tracker_skill,
                  index: { name: "index_tt_skill_certifications_on_skill_id" },
                  foreign_key: { to_table: :decidim_time_tracker_skills }

    # Certifications are now per (user, task, skill), with a NULL skill for
    # tasks that have no explicit skills (the task name acts as the skill).
    remove_index :decidim_time_tracker_skill_certifications,
                 name: "index_tt_skill_certifications_on_user_and_task",
                 if_exists: true

    add_index :decidim_time_tracker_skill_certifications,
              [:decidim_user_id, :decidim_time_tracker_task_id],
              unique: true,
              where: "decidim_time_tracker_skill_id IS NULL",
              name: "index_tt_skill_certs_unique_task_fallback"

    add_index :decidim_time_tracker_skill_certifications,
              [:decidim_user_id, :decidim_time_tracker_task_id, :decidim_time_tracker_skill_id],
              unique: true,
              where: "decidim_time_tracker_skill_id IS NOT NULL",
              name: "index_tt_skill_certs_unique_task_skill"
  end

  def down
    remove_column :decidim_time_tracker_skills, :required_completions_per_activity, if_exists: true
    remove_index :decidim_time_tracker_skill_certifications, name: "index_tt_skill_certs_unique_task_fallback", if_exists: true
    remove_index :decidim_time_tracker_skill_certifications, name: "index_tt_skill_certs_unique_task_skill", if_exists: true
    remove_column :decidim_time_tracker_skill_certifications, :decidim_time_tracker_skill_id, if_exists: true

    add_index :decidim_time_tracker_skill_certifications,
              [:decidim_user_id, :decidim_time_tracker_task_id],
              unique: true,
              name: "index_tt_skill_certifications_on_user_and_task"
  end
end
