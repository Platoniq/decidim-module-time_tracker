# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe UpdateAssignation do
    let(:subject) { described_class.new(assignation, user, status) }
    let(:organization) { create :organization }
    let(:task) { create :task }
    let(:activity) { create :activity, task: task }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:user_2) { create :user, :confirmed, organization: organization }
    let(:assignation) { create :assignation, activity: activity, user: user_2, status: :pending }
    let(:status) { :accepted }

    context "when the admin accepts the assignation" do
      before do
        subject.call
        assignation.reload
      end

      it "updates the invited by user field and the status" do
        expect(assignation.status.to_sym).to eq(status)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(assignation, user, hash_including(status: :accepted))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
