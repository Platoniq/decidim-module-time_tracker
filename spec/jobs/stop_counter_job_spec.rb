# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe StopCounterJob do
    let(:activity) { create :activity, max_minutes_per_day: 60 }
    let(:assignee) { create(:assignee, activity: activity) }
    let!(:time_event) { create :time_event, assignee: assignee, activity: activity, start: start_time.to_i }

    let(:start_time) { Date.current + 12.hours - 30.minutes }

    # Mock Time.current to middle of the day, to avoid pass-day incoherences
    before do
      allow(Time).to receive(:current).and_return(Date.current + 12.hours)
    end

    context "when time event has still time available" do
      it "do not stop the counter" do
        StopCounterJob.perform_now(time_event)

        expect(time_event.stopped?).to eq(false)
        expect(time_event.stop).to eq(nil)
      end
    end

    context "when time event has consumed all available time" do
      let(:start_time) { Date.current + 12.hours - 60.minutes }

      it "stops the counter" do
        StopCounterJob.perform_now(time_event)

        expect(time_event.stopped?).to eq(true)
        expect(time_event.stop).to eq(Time.current.to_i)
      end
    end

    context "when time event passed to the next day" do
      let(:start_time) { Date.current + 1.day - 1.minute }

      before do
        allow(Time).to receive(:current).and_return(Date.current + 25.hours)
      end

      it "stops the counter" do
        StopCounterJob.perform_now(time_event)

        expect(time_event.stopped?).to eq(true)
        expect(time_event.stop).to eq(Time.current.to_i)
      end
    end

    context "when there are several events on the same day" do
      let!(:time_event1) { create :time_event, assignee: assignee, activity: activity, start: (start_time.to_i - 2.hours.to_i), stop: (start_time.to_i - 2.hours.to_i + 15.minutes.to_i) }

      context "and there's still time" do
        it "do not stop the counter" do
          StopCounterJob.perform_now(time_event)

          expect(time_event.stopped?).to eq(false)
          expect(time_event.stop).to eq(nil)
        end
      end

      context "and time's up" do
        let!(:time_event2) { create :time_event, assignee: assignee, activity: activity, start: (start_time.to_i - 1.hour.to_i), stop: (start_time.to_i - 1.hour.to_i + 15.minutes.to_i) }

        it "stops the counter" do
          StopCounterJob.perform_now(time_event)

          expect(time_event.stopped?).to eq(true)
          expect(time_event.stop).to eq(Time.current.to_i)
        end
      end
    end
  end
end
