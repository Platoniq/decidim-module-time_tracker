# frozen_string_literal: true

class CreateDecidimTimeTrackerMilestones < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_tracker_milestones do |t|
      t.references :time_tracker, foreign_key: { to_table: :decidim_time_trackers }, index: true
      t.references :decidim_user, null: false, index: true
      t.jsonb :title
      t.jsonb :description
    end
  end
end
