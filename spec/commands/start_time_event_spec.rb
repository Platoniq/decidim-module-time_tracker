# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe StartTimeEvent do
    let(:subject) { described_class.new(form) }
    let(:activity) { create :activity, max_minutes_per_day: 60 }
    let(:user) { create :user, :confirmed, organization: organization }
    let(:assignee) { create :assignee, user: user, activity: activity, status: status }
    let(:status) { :accepted }
    let(:organization) { create :organization }
    let(:start_time) { Date.current + 12.hours - 30.minutes }
    let(:stop_time) { Date.current + 12.hours - 15.minutes }

    let(:form) do
      TimeEventForm.from_params(attributes)
    end

    let(:attributes) do
      {
        activity: activity,
        assignee: assignee
      }
    end

    # Mock Time.current to middle of the day, to avoid pass-day incoherences
    before do
      allow(Time).to receive(:current).and_return(Date.current + 12.hours)
    end

    shared_examples "returns ok" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new time event" do
        expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(1)
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

    context "when the user is assigned to the activity" do
      it_behaves_like "returns ok"
    end

    context "when user is not assigned to the activity" do
      let(:attributes) do
        {
          activity: create(:activity),
          assignee: assignee
        }
      end

      it_behaves_like "returns error", :assignee
    end

    context "when user is not accepted to the activity" do
      let(:status) { "rejected" }

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

    context "when user is tracking another activity" do
      let!(:prev_entry) { create(:time_event, start: start_time, assignee: assignee) }

      it_behaves_like "returns ok"

      it "stops the previous activity" do
        subject.call
        prev = Decidim::TimeTracker::TimeEvent.where(activity: prev_entry.activity).last_for(user)
        last = Decidim::TimeTracker::TimeEvent.where(activity: activity).last_for(user)

        expect(prev.stopped?).to eq(true)
        expect(prev.stop).not_to be(nil)
        expect(prev.total_seconds).not_to be(0)
        expect(prev.total_seconds).to be(prev.stop - prev.start)
        expect(prev.stop).to eq(last.start)
      end
    end

    context "when last entry is still running" do
      let(:last_assignee) { assignee }
      let!(:last_entry) { create(:time_event, start: start_time, assignee: last_assignee, activity: activity) }

      context "and last assignee is not the same user" do
        let(:last_assignee) { create(:assignee) }

        it_behaves_like "returns ok"
      end

      context "and there's previous stopped events" do
        let!(:last_entry) { create(:time_event, start: start_time, stop: stop_time, assignee: last_assignee, activity: activity) }

        it_behaves_like "returns ok"
      end

      context "and still has minutes available for the day" do
        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:already_active)
        end

        it "do not create a new time event" do
          expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(0)
        end
      end

      context "and there are more time accumulated than the allowed" do
        let(:start) { Time.current - 2.hours }
        let(:stop) { Time.current - 59.minutes }
        let!(:older_entry) { create(:time_event, start: start, stop: stop, total_seconds: stop - start, assignee: assignee, activity: activity) }

        it_behaves_like "returns error", :activity
      end
    end

    context "when start and stop are in different days" do
      let!(:older_entry) { create(:time_event, start: start, stop: stop, total_seconds: stop - start, assignee: assignee, activity: activity) }

      context "and start is in the previous day" do
        let(:start) { Date.current - 30.minutes }
        let(:stop) { Date.current + 31.minutes }

        it_behaves_like "returns ok"
      end
    end
  end
end
