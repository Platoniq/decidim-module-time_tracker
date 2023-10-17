# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe DestroyActivity do
    subject { described_class.new(activity, user) }

    let(:organization) { create :organization }
    let(:activity) { create :activity, task: task }
    let(:task) { create :task }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }

    context "when everything is ok" do
      it "destroys the activity" do
        subject.call
        expect { activity.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with(:delete, activity, user)
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
