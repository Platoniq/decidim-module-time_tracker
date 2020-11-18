# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe StopLastTimeEvent do
    let(:subject) { described_class.new(user) }
    let(:activity) { create :activity, max_minutes_per_day: 60 }
    let(:user) { create :user, :confirmed }
    let(:assignation) { create :assignation, user: user, activity: activity, status: status }

    let!(:time_event) { create :time_event, user: user, activity: activity, start: start_time.to_i }

    let(:start_time) { Date.current + 12.hours - 30.minutes }
    let(:stop_time) { Date.current + 12.hours - 15.minutes }
    # Mock Time.current to middle of the day, to avoid pass-day incoherences

    before do
      allow(Time).to receive(:current).and_return(Date.current + 12.hours)
    end

    shared_examples "returns ok" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "do not create a new time event" do
        expect { subject.call }.to change { Decidim::TimeTracker::TimeEvent.count }.by(0)
      end

      it "event is stopped" do
        subject.call
        last = Decidim::TimeTracker::TimeEvent.last_for(user)

        expect(last.stopped?).to eq(true)
        expect(last.stop).to eq(Time.current.to_i)
        expect(last.total_seconds).to be(30 * 60)
        expect(last.total_seconds).to be(last.stop.to_i - last.start)
      end
    end

    shared_examples "returns already_stopped" do
      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:already_stopped)
      end
    end

    shared_examples "returns error" do
      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the user has started the counter" do
      it_behaves_like "returns ok"
    end

    context "when the user has not started the counter" do
      let!(:time_event) { create :time_event, user: user, activity: activity, start: start_time.to_i, stop: stop_time.to_i }

      it_behaves_like "returns already_stopped"

      context "when the last entry is not the user" do
        let!(:time_event) { create :time_event, user: user, activity: activity, start: start_time.to_i, stop: stop_time.to_i }
        let!(:another_time_event) { create :time_event, activity: activity, start: (start_time.to_i + 1), stop: (stop_time.to_i + 1) }

        it_behaves_like "returns already_stopped"
      end
    end
  end
end
