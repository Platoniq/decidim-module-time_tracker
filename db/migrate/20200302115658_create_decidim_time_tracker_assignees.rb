# frozen_string_literal: true

class CreateDecidimTimeTrackerAssignees < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_assignees do |t|
      t.references :decidim_user,
                   foreign_key: { to_table: :decidim_users },
                   index: true
      t.timestamps
    end
  end
end
