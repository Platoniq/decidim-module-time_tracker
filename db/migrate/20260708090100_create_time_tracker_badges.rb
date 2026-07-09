# frozen_string_literal: true

class CreateTimeTrackerBadges < ActiveRecord::Migration[7.0]
  def change
    create_table :decidim_time_tracker_badges do |t|
      t.jsonb :name, null: false, default: {}
      t.jsonb :description, default: {}
      t.string :metric, null: false
      t.integer :levels, array: true, null: false, default: []
      t.boolean :active, null: false, default: true
      t.integer :weight, null: false, default: 0
      t.references :decidim_organization,
                   null: false,
                   index: { name: "index_tt_badges_on_organization_id" },
                   foreign_key: { to_table: :decidim_organizations }
      t.timestamps
    end
  end
end
