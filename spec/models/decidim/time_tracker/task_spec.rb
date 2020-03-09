# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Task do
      subject { task }

      let(:time_tracker) { create(:time_tracker) }
      let(:activities) { create_list(:activity, 3) }
      let(:task) { create(:task, time_tracker: time_tracker, activities: activities) }

      it { is_expected.to be_valid }

      context "when the task is correctly associated" do
        it "is associated with a time tracker" do
          expect(subject.time_tracker).to eq(time_tracker)
        end

        it "is associated with activities" do
          expect(subject.activities.first.id).to eq(activities.first.id)
          expect(subject.activities.second.id).to eq(activities.second.id)
          expect(subject.activities.third.id).to eq(activities.third.id)
        end
      end

      context "when changing the time tracker" do
        let!(:time_tracker) { create(:time_tracker) }

        before do
          task.update(time_tracker: time_tracker)
        end

        it "updates the time tracker" do
          expect(task.time_tracker.id).to eq(time_tracker.id)
        end
      end

      context "when adding a new activity" do
        let!(:new_activity) { create(:activity, task: task) }

        it "updates the activities" do
          expect(task.activities.count).to eq 4
          expect(task.activities.reload.last.id).to eq(new_activity.id)
        end
      end
    end
  end
end
