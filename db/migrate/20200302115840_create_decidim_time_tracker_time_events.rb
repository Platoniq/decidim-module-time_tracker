# frozen_string_literal: true

class CreateDecidimTimeTrackerTimeEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_time_events do |t|
      t.references :assignation, foreign_key: { to_table: :decidim_time_tracker_assignations }
      t.integer :start # timestamp (seconds)
      t.integer :stop # timestamp (seconds)
      t.integer :total_seconds, null: false, default: 0
      t.timestamps
    end
  end
end
