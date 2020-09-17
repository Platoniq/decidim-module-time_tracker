# frozen_string_literal: true

class AddEstimatedTimeToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_time_tracker_activities, :estimated_time, :integer
  end
end
