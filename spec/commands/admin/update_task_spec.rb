# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe UpdateTask do
    let(:subject) { described_class.new(task, form, user) }
    let(:organization) { create :organization }
    let(:component) { create :time_tracker_component }
    let(:time_tracker) { create(:time_tracker, component: component) }
    let(:task) { create(:task, time_tracker: time_tracker) }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:form) do
      double(
        # taskForm,
        name: Decidim::Faker::Localized.word,
        invalid?: invalid,
        current_user: user
      )
    end

    let(:invalid) { false }

    context "when the form is not valid" do
      let(:invalid) { true }

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the form is valid" do
      before do
        subject.call
        task.reload
      end

      it "updates the name of the task" do
        expect(task.name).to eq(form.name)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(task, user, hash_including(name: form.name))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
