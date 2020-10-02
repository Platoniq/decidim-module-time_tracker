# frozen_string_literal: true

class AddDecidimTimeTrackerMilestoneActivity < ActiveRecord::Migration[5.2]
  def change
    add_reference :decidim_time_tracker_milestones, :activity, foreign_key: { to_table: :decidim_time_tracker_activities }, null: false
    remove_column :decidim_time_tracker_milestones, :decidim_component_id
  end
end
