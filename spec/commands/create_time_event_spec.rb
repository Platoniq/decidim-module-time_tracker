# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe CreateTimeEvent do
    let(:subject) { described_class.new(form, current_user) }
    let(:activity) { create :activity, max_minutes_per_day: 60 }
    let(:user) { create :user, :confirmed, organization: organization }
    let(:assignee) { create :assignee, user: user, activity: activity, status: status }
    let(:current_user) { user }
    let(:status) { :accepted }
    let(:organization) { create :organization }
    let(:action) { :start }

    let(:form) do
      TimeEventForm.from_params(attributes)
    end

    let(:attributes) do
      {
        activity: activity,
        assignee: assignee,
        action: action
      }
    end

    context "when the user is assigned to the activity" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new time event" do
        expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(1)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:create!)
          .with(Decidim::TimeTracker::TimeEvent, user, hash_including(:activity, :action, :assignee))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end

    shared_examples "returns error" do |attribute|
      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end

      it "do not create a new time event" do
        expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(0)
      end

      it "form returns error" do
        subject.call
        expect(form.errors[attribute]).not_to be_empty
      end
    end

    context "when user is not assigned to the activity" do
      let(:attributes) do
        {
          activity: create(:activity),
          assignee: assignee,
          action: action
        }
      end

      it_behaves_like "returns error", :assignee
    end

    context "when activity is not active" do
      let(:activity) { create :activity, active: false }

      it_behaves_like "returns error", :activity
    end

    context "when activity has not started yet" do
      let(:activity) { create :activity, start_date: 1.day.from_now }

      it_behaves_like "returns error", :activity
    end

    context "when activity has finished already" do
      let(:activity) { create :activity, end_date: 1.day.ago }

      it_behaves_like "returns error", :activity
    end

    context "when last entry is a start event" do
      before do
        allow(Time).to receive(:current).and_return(Date.current + 12.hours)
      end

      let(:last_assignee) { assignee }
      let(:created) { 15.minutes.ago }
      let!(:last_entry) { create(:time_event, action: :start, assignee: last_assignee, activity: activity, created_at: created) }

      context "and last assignee is not the same user" do
        let(:last_assignee) { create(:assignee) }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end
      end

      context "and still has minutes available for the day" do
        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "do not create a new time event" do
          expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(0)
        end
      end

      context "and is more than the maximum amount of time allowed" do
        let(:created) { 61.minutes.ago }

        it_behaves_like "returns error", :activity
      end

      context "and there are more time accumulated than the allowed" do
        let!(:older_entry1) { create(:time_event, action: :start, assignee: last_assignee, activity: activity, created_at: Time.current - 2.hours) }
        let!(:older_entry2) { create(:time_event, action: :stop, total_seconds: 60, assignee: last_assignee, activity: activity, created_at: Time.current - 1.hour) }

        it_behaves_like "returns error", :activity
      end
    end

    context "when entry is a stop event" do
      let(:action) { :stop }

      context "and there are no entries for the user" do
        let!(:last_entry) { create(:time_event, action: :start) }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "do not create a new time event" do
          expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(0)
        end
      end

      context "and last entry is a stop event" do
        let!(:last_entry) { create(:time_event, action: :stop, assignee: assignee, activity: activity) }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "do not create a new time event" do
          expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(0)
        end
      end
    end
  end
end
