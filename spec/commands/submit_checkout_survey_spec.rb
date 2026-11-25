# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe SubmitCheckoutSurvey do
    subject { described_class.new(form, activity:, user:, donation_enabled:) }

    let(:user) { create(:user, :confirmed) }
    let(:activity) { create(:activity) }
    let(:assignation) { create(:assignation, user:, activity:) }
    let!(:time_event) { create(:time_event, :stopped, assignation:, activity:, user:) }
    let(:donation_enabled) { true }
    let(:params) do
      { time_event_id: time_event.id, work_nature: 2, work_value: 5, involved: %w(creating caring), usually_paid: "no" }
    end
    let(:form) { CheckoutSurveyForm.from_params(checkout_survey: params) }

    it "saves the answers for the time entry" do
      expect { subject.call }.to broadcast(:ok)
      response = time_event.reload.checkout_response
      expect(response).to have_attributes(user:, activity:, work_nature: 2, work_value: 5, usually_paid: "no")
      expect(response.involved).to eq(%w(creating caring))
    end

    it "does not save twice for the same time entry" do
      subject.call
      expect { described_class.new(CheckoutSurveyForm.from_params(checkout_survey: params), activity:, user:, donation_enabled:).call }.to broadcast(:invalid)
      expect(CheckoutResponse.count).to eq(1)
    end

    context "when the time entry is someone else's" do
      let!(:time_event) { create(:time_event, :stopped, activity:) }

      it { expect { subject.call }.to broadcast(:invalid) }
    end

    context "when the timer is still running" do
      let!(:time_event) { create(:time_event, :running, assignation:, activity:, user:) }

      it { expect { subject.call }.to broadcast(:invalid) }
    end

    context "with an unknown choice" do
      let(:params) { super().merge(involved: %w(hacking)) }

      it { expect { subject.call }.to broadcast(:invalid) }
    end

    context "when the volunteer donates data" do
      let(:params) do
        super().merge(donate: "true", age_range: "18_24", ethnicity: " Latina ", gender_identities: %w(non_binary gender_fluid),
                      disability: "", migrant_background: "first_generation")
      end

      it "stores the donation with the consent" do
        expect { subject.call }.to change(DataDonation, :count).by(1)
        expect(DataDonation.last).to have_attributes(user:, consented: true, consent_version: DataDonation::CONSENT_VERSION,
                                                     age_range: "18_24", ethnicity: "Latina", disability: nil,
                                                     gender_identities: %w(non_binary gender_fluid), migrant_background: "first_generation")
        expect(DataDonation.last.consented_at).to be_present
      end

      context "when the component does not ask for donations" do
        let(:donation_enabled) { false }

        it { expect { subject.call }.not_to change(DataDonation, :count) }
      end

      context "when the volunteer already answered" do
        before { create(:data_donation, user:, consented: false, age_range: nil, gender_identities: []) }

        it { expect { subject.call }.not_to change(DataDonation, :count) }
      end
    end

    context "when the volunteer does not want to be asked again" do
      let(:params) { super().merge(decline_donation: "true", age_range: "18_24") }

      it "remembers the answer without storing any data" do
        subject.call
        expect(DataDonation.last).to have_attributes(user:, consented: false, age_range: nil)
      end
    end

    context "without consent" do
      let(:params) { super().merge(age_range: "18_24") }

      it { expect { subject.call }.not_to change(DataDonation, :count) }
    end
  end
end
