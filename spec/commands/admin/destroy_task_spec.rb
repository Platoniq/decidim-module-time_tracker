# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe DestroyTask do
    subject { described_class.new(task, user) }

    let(:organization) { create(:organization) }
    let(:task) { create(:task) }
    let(:user) { create(:user, :confirmed, :admin, organization:) }

    context "when everything is ok" do
      it "destroys the task" do
        subject.call
        expect { task.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "traces the action", :versioning do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with(:delete, task, user)
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
