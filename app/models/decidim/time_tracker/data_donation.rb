# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Demographic data a volunteer chose to donate for the policy tracker.
    #
    # Never shown next to a name: admins only see totals, and any group smaller
    # than MIN_GROUP is hidden. A row with consented: false means the volunteer
    # said "don't ask me again" and holds no data. Withdrawing deletes the row,
    # and so does deleting the account (see the engine).
    class DataDonation < ApplicationRecord
      self.table_name = :decidim_time_tracker_data_donations

      CONSENT_VERSION = "2026-11"
      MIN_GROUP = 10
      AGE_RANGES = %w(under_18 18_24 25_34 35_44 45_54 55_64 65_plus).freeze
      GENDER_IDENTITIES = %w(woman man non_binary gender_fluid agender trans).freeze
      DISABILITY = %w(yes no).freeze
      MIGRANT_BACKGROUND = %w(no first_generation second_generation).freeze

      belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"
      belongs_to :organization, foreign_key: "decidim_organization_id", class_name: "Decidim::Organization"

      validates :age_range, inclusion: { in: AGE_RANGES }, allow_blank: true
      validates :disability, inclusion: { in: DISABILITY }, allow_blank: true
      validates :migrant_background, inclusion: { in: MIGRANT_BACKGROUND }, allow_blank: true
      validates :ethnicity, :gender_self_described, length: { maximum: 100 }
      validate :gender_identities_known

      scope :consented, -> { where(consented: true) }

      # Whether the volunteer has already answered (donated or declined).
      def self.answered_by?(user)
        exists?(user:)
      end

      private

      def gender_identities_known
        errors.add(:gender_identities, :inclusion) unless Array(gender_identities).all? { |item| GENDER_IDENTITIES.include?(item) }
      end
    end
  end
end
