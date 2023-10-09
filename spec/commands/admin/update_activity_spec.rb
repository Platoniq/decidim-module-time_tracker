# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe UpdateActivity do
    let(:subject) { described_class.new(activity, form, user) }
    let(:organization) { create :organization }
    let(:task) { create :task }
    let(:activity) { create :activity, task: task }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:form) do
      double(
        # activityForm,
        description: Decidim::Faker::Localized.word,
        active: true,
        start_date: 1.day.from_now,
        end_date: 1.month.from_now,
        max_minutes_per_day: 60,
        requests_start_at: Faker::Time.between(from: 10.days.ago, to: 1.day.ago),
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
        activity.reload
      end

      it "updates the description of the activity" do
        expect(activity.description).to eq(form.description)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(activity, user, hash_including(description: form.description))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
