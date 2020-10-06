# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeEventForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:user) { create(:user) }
    let(:assignee) { create(:assignee, activity: activity) }
    let(:activity) { create(:activity) }
    let(:start) { Time.current }
    let(:stop) { nil }

    let(:attributes) do
      {
        activity: activity,
        user_id: user.id,
        assignee: assignee,
        start: start,
        stop: stop
      }
    end

    it { is_expected.to be_valid }

    context "when user is not assgined to activity" do
      let(:assignee) { create(:assignee) }

      it { is_expected.to be_invalid }
    end

    context "when start is not a Time" do
      let(:start) { 2134 }

      it { is_expected.to be_invalid }
    end

    context "when stop is not a Time" do
      let(:stop) { 1234 }

      it { is_expected.to be_invalid }
    end

    context "when stop is lower than start" do
      let(:stop) { Time.current - 10.minutes }

      it { is_expected.to be_invalid }
    end

    context "when no user is assigned" do
      let(:attributes) do
        {
          activity: activity,
          assignee: assignee,
          start: start
        }
      end

      it { is_expected.to be_valid }

      it "assignes user to assignee" do
        expect(form.user).to be_a(Decidim::User)
        expect(form.user).to eq(assignee.user)
      end
    end
  end
end
