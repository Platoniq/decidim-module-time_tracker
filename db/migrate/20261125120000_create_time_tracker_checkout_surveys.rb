# frozen_string_literal: true

# Check-out survey (policy tracker, 25 Nov 2026): how volunteers value the work
# they just did, plus demographic data they may choose to donate.
class CreateTimeTrackerCheckoutSurveys < ActiveRecord::Migration[7.0]
  def change
    # One answer per stopped time entry.
    create_table :decidim_time_tracker_checkout_responses do |t|
      t.references :decidim_time_tracker_time_event,
                   null: false,
                   index: { unique: true, name: "index_tt_checkout_responses_on_time_event_id" },
                   foreign_key: { to_table: :decidim_time_tracker_time_events, on_delete: :cascade }
      t.references :decidim_time_tracker_activity,
                   null: false,
                   index: { name: "index_tt_checkout_responses_on_activity_id" },
                   foreign_key: { to_table: :decidim_time_tracker_activities, on_delete: :cascade }
      t.references :decidim_user,
                   null: false,
                   index: { name: "index_tt_checkout_responses_on_user_id" },
                   foreign_key: { to_table: :decidim_users }
      t.integer :work_nature # 1 mostly intellectual .. 5 mostly physical
      t.integer :work_value # 1 non-productive .. 5 productive
      t.jsonb :involved, null: false, default: []
      t.string :usually_paid # yes / no / not_sure
      t.timestamps
    end

    # Optional demographic data a volunteer donates, one row per person. It is kept
    # out of every page that shows names and only ever reported in totals of at least
    # 10 people. Withdrawing deletes the row; so does deleting the account.
    create_table :decidim_time_tracker_data_donations do |t|
      t.references :decidim_user,
                   null: false,
                   index: { unique: true, name: "index_tt_data_donations_on_user_id" },
                   foreign_key: { to_table: :decidim_users }
      t.references :decidim_organization,
                   null: false,
                   index: { name: "index_tt_data_donations_on_organization_id" },
                   foreign_key: { to_table: :decidim_organizations }
      t.boolean :consented, null: false, default: false # false = "don't ask me again", no data
      t.datetime :consented_at
      t.string :consent_version
      t.string :age_range
      t.string :ethnicity
      t.jsonb :gender_identities, null: false, default: []
      t.string :gender_self_described
      t.string :disability
      t.string :migrant_background
      t.timestamps
    end
  end
end
