# frozen_string_literal: true

class CreateDecidimTimeTrackerAssignations < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_assignations do |t|
      t.references :decidim_time_tracker_assignee,
        foreign_key: { to_table: :decidim_time_tracker_assignees },
        index: { name: :index_decidim_time_tracker_assignations_assignee },
        null: false
      t.references :activity,
        foreign_key: { to_table: :decidim_time_tracker_activities },
        index: { name: :index_decidim_time_tracker_assignations_activity },
        null: false
      t.integer :status, default: 0
      t.datetime :invited_at
      t.references :invited_by_user, foreign_key: { to_table: :decidim_users }
      t.datetime :requested_at
      t.datetime :tos_accepted_at
      t.timestamps
    end
  end
end
