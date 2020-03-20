# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateActivity do
    let(:subject) { described_class.new(form, task) }
    let(:form) do
      double(
        # activityForm,
        description: Decidim::Faker::Localized.word,
        active: true,
        start_date: 1.day.from_now,
        end_date: 1.month.from_now,
        max_minutes_per_day: 60,
        requests_start_at: Faker::Time.between(10.days.ago, 1.day.ago),
        invalid?: invalid,
        current_user: user
      )
    end

    let(:task) { create :task }
    let(:user) { create :user, :admin, :confirmed, organization: organization }
    let(:organization) { create :organization }
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

      it "creates a new activity for the task" do
        expect { subject.call }.to change { Decidim::TimeTracker::Activity.count }.by(1)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:create!)
          .with(Decidim::TimeTracker::Activity, user, hash_including(:description, :active, :start_date, :end_date, :max_minutes_per_day, :requests_start_at))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
