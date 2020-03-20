# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateTask do
    let(:subject) { described_class.new(form, time_tracker) }
    let(:form) do
      double(
        # taskForm,
        time_tracker: time_tracker,
        name: Decidim::Faker::Localized.word,
        invalid?: invalid,
        current_user: user
      )
    end

    let(:time_tracker) { create :time_tracker }
    let(:organization) { create :organization }
    let(:user) { create :user, :admin, :confirmed, organization: organization }

    let(:invalid) { false }

    context "when the form is not valid" do
      let(:invalid) { true }

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the form is valid" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new task for the organization" do
        expect { subject.call }.to change { Decidim::TimeTracker::Task.count }.by(1)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:create!)
          .with(Decidim::TimeTracker::Task, user, hash_including(:name))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
