# frozen_string_literal: true

class ChangeDecidimTimeTrackerMilestoneTitle < ActiveRecord::Migration[5.2]
  def change
    change_column :decidim_time_tracker_milestones, :title, :string
    change_column :decidim_time_tracker_milestones, :description, :string
  end
end
