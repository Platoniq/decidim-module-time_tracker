# frozen_string_literal: true

class CreateDecidimTimeTrackerMilestones < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_milestones do |t|
      t.references :decidim_user, null: false, index: true
      t.references :activity, foreign_key: { to_table: :decidim_time_tracker_activities }, null: false
      t.string :title
      t.string :description
      t.timestamps
    end
  end
end
