# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The check-out survey: how the volunteer values the work they just did,
    # and, if they agree, the demographic data they donate. Every question is
    # optional ("prefer not to say" is simply leaving it blank).
    class CheckoutSurveyForm < Decidim::Form
      mimic :checkout_survey

      attribute :time_event_id, Integer
      attribute :work_nature, Integer
      attribute :work_value, Integer
      attribute :involved, [String]
      attribute :usually_paid, String

      attribute :donate, Boolean, default: false
      attribute :decline_donation, Boolean, default: false
      attribute :age_range, String
      attribute :ethnicity, String
      attribute :gender_identities, [String]
      attribute :gender_self_described, String
      attribute :disability, String
      attribute :migrant_background, String

      validates :time_event_id, presence: true
      validates :work_nature, :work_value, inclusion: { in: CheckoutResponse::SCALE }, allow_nil: true
      validates :usually_paid, inclusion: { in: CheckoutResponse::USUALLY_PAID }, allow_blank: true
      validates :age_range, inclusion: { in: DataDonation::AGE_RANGES }, allow_blank: true
      validates :disability, inclusion: { in: DataDonation::DISABILITY }, allow_blank: true
      validates :migrant_background, inclusion: { in: DataDonation::MIGRANT_BACKGROUND }, allow_blank: true
      validates :ethnicity, :gender_self_described, length: { maximum: 100 }
      validate :known_choices

      def involved
        super.to_a.compact_blank.uniq
      end

      def gender_identities
        super.to_a.compact_blank.uniq
      end

      private

      def known_choices
        errors.add(:involved, :inclusion) unless (involved - CheckoutResponse::INVOLVED).empty?
        errors.add(:gender_identities, :inclusion) unless (gender_identities - DataDonation::GENDER_IDENTITIES).empty?
      end
    end
  end
end
