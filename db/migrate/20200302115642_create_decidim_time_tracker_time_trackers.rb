# frozen_string_literal: true

class CreateDecidimTimeTrackerTimeTrackers < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_time_trackers do |t|
      t.references :decidim_component, index: true
      t.timestamps
    end
  end
end
