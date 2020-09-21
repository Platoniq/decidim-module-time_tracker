# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeEventForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:user) { create(:user) }
    let(:assignee) { create(:assignee) }
    let(:activity) { create(:activity) }
    let(:action) { :start }

    let(:attributes) do
      {
        activity: activity,
        user_id: user.id,
        assignee: assignee,
        action: action
      }
    end

    it { is_expected.to be_valid }

    context "when action is stop" do
      let(:action) { :stop }

      it { is_expected.to be_valid }
    end

    context "when action is not be_valid" do
      let(:action) { :weird_action }

      it { is_expected.to be_invalid }
    end

    context "when no user is assigned" do
      let(:attributes) do
        {
          activity: activity,
          assignee: assignee,
          action: action
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
