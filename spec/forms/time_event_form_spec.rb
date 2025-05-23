# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeEventForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:user) { create(:user) }
    let(:assignation) { create(:assignation, activity:) }
    let(:activity) { create(:activity) }
    let(:start) { Time.current.to_date }
    let(:stop) { nil }

    let(:attributes) do
      {
        activity:,
        user_id: user.id,
        assignation:,
        start:,
        stop:
      }
    end

    it { is_expected.to be_valid }

    context "when user is not assgined to activity" do
      let(:assignation) { create(:assignation) }

      it { is_expected.not_to be_valid }
    end

    context "when start is not a Time" do
      let(:start) { 2134 }

      it { is_expected.not_to be_valid }
    end

    context "when stop is not a Time" do
      let(:stop) { 1234 }

      it { is_expected.not_to be_valid }
    end

    context "when stop is lower than start" do
      let(:stop) { 10.minutes.ago }

      it { is_expected.not_to be_valid }
    end

    context "when no user is assigned" do
      let(:attributes) do
        {
          activity:,
          assignation:,
          start:
        }
      end

      it { is_expected.to be_valid }

      it "assignes user to assignation" do
        expect(form.user).to be_a(Decidim::User)
        expect(form.user).to eq(assignation.user)
      end
    end
  end
end
