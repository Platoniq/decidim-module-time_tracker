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
        let!(:time_entries) { create_list(:time_entry, 3, activity: activity) }

        it "is associated with a task" do
          expect(subject.task). to eq(task)
        end

        it "is associated with assignees" do
          expect(subject.time_entries.count).to eq time_entries.count
          expect(subject.time_entries.first.id).to eq(time_entries.first.id)
          expect(subject.time_entries.second.id).to eq(time_entries.second.id)
          expect(subject.time_entries.third.id).to eq(time_entries.third.id)
        end

        it "is associated with time_entries" do
          expect(subject.assignees.count).to eq assignees.count
          expect(subject.assignees.first.id).to eq(assignees.first.id)
          expect(subject.assignees.second.id).to eq(assignees.second.id)
        end
      end
    end
  end
end
