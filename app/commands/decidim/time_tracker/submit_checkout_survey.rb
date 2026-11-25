# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Saves the check-out survey for one of the current user's stopped time
    # entries, and the donated data when the volunteer agreed (or their
    # "don't ask me again").
    #
    # Broadcasts :ok with the response, or :invalid.
    class SubmitCheckoutSurvey < Decidim::Command
      def initialize(form, activity:, user:, donation_enabled:)
        @form = form
        @activity = activity
        @user = user
        @donation_enabled = donation_enabled
      end

      def call
        return broadcast(:invalid) if form.invalid? || time_event.nil? || time_event.checkout_response.present?

        response = nil
        transaction do
          response = CheckoutResponse.create!(
            time_event:,
            activity:,
            user:,
            work_nature: form.work_nature,
            work_value: form.work_value,
            involved: form.involved,
            usually_paid: form.usually_paid.presence
          )
          save_donation!
        end

        broadcast(:ok, response)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        broadcast(:invalid)
      end

      private

      attr_reader :form, :activity, :user

      # Only the volunteer's own, already stopped, entry on this activity.
      def time_event
        return @time_event if defined?(@time_event)

        event = TimeEvent.where(user:, activity:).find_by(id: form.time_event_id) # rubocop:disable Decidim/OrganizationScopedFinder -- the current user's own entries
        @time_event = event&.stopped? ? event : nil
      end

      def save_donation!
        return unless @donation_enabled
        return if DataDonation.answered_by?(user)

        if form.donate
          DataDonation.create!(
            user:,
            organization: user.organization,
            consented: true,
            consented_at: Time.current,
            consent_version: DataDonation::CONSENT_VERSION,
            age_range: form.age_range.presence,
            ethnicity: form.ethnicity.to_s.strip.presence,
            gender_identities: form.gender_identities,
            gender_self_described: form.gender_self_described.to_s.strip.presence,
            disability: form.disability.presence,
            migrant_background: form.migrant_background.presence
          )
        elsif form.decline_donation
          DataDonation.create!(user:, organization: user.organization, consented: false)
        end
      end
    end
  end
end
