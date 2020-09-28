# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Activity do
      subject { activity }

      let(:task) { create(:task) }
      let(:activity) { create(:activity, task: task) }

      it { is_expected.to be_valid }

      context "when the activity is correctly associated" do
        let!(:assignees) { create_list(:assignee, 2, activity: activity) }
        let!(:time_events) do
          [
            create(:time_event, activity: activity, start: 1000),
            create(:time_event, activity: activity, start: 2000),
            create(:time_event, activity: activity, start: 3000)
          ]
        end

        it "is associated with a task" do
          expect(subject.task). to eq(task)
        end

        it "is associated with time_events in reverse order" do
          expect(subject.time_events.count).to eq time_events.count
          expect(subject.time_events.first.id).to eq(time_events.third.id)
          expect(subject.time_events.second.id).to eq(time_events.second.id)
          expect(subject.time_events.third.id).to eq(time_events.first.id)
        end

        it "is associated with assignees" do
          expect(subject.assignees.count).to eq assignees.count
          expect(subject.assignees.first.id).to eq(assignees.first.id)
          expect(subject.assignees.second.id).to eq(assignees.second.id)
        end
      end
    end
  end
end
