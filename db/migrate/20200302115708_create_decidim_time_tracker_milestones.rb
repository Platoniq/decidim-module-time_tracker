# frozen_string_literal: true

class CreateDecidimTimeTrackerMilestones < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_milestones do |t|
      t.references :assignation, foreign_key: { to_table: :decidim_time_tracker_assignations }, null: false
      t.string :title
      t.string :description
      t.timestamps
    end
  end
end
