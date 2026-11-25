# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe DataDonation do
    subject { build(:data_donation) }

    it { is_expected.to be_valid }

    it "refuses unknown gender identities" do
      subject.gender_identities = %w(woman robot)
      expect(subject).not_to be_valid
    end

    it "refuses unknown age ranges" do
      subject.age_range = "ancient"
      expect(subject).not_to be_valid
    end

    describe "when the account is deleted" do
      let(:user) { create(:user, :confirmed) }
      let!(:donation) { create(:data_donation, user:) }
      let(:form) { Decidim::DeleteAccountForm.from_params(delete_reason: "bye").with_context(current_user: user) }

      it "deletes the donated data" do
        expect { Decidim::DestroyAccount.call(form) }.to change(described_class, :count).by(-1)
      end
    end
  end
end
