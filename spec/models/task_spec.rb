# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Task do
      subject { task }

      let(:component) { create(:time_tracker_component) }
      let(:activities) { create_list(:activity, 3) }
      let(:task) { create(:task, component: component, activities: activities) }

      it { is_expected.to be_valid }

      context "when the task is correctly associated" do
        it "is associated with a time tracker component" do
          expect(subject.component).to eq(component)
        end

        it "is associated with activities" do
          expect(subject.activities.first.id).to eq(activities.first.id)
          expect(subject.activities.second.id).to eq(activities.second.id)
          expect(subject.activities.third.id).to eq(activities.third.id)
        end
      end

      context "when adding a new activity" do
        let!(:new_activity) { create(:activity, task: task) }

        it "updates the activities" do
          expect(task.activities.count).to eq 4
          expect(task.activities.reload.last.id).to eq(new_activity.id)
        end
      end

      context "when the task has questions" do
        let!(:question) { create(:questionnaire_question, questionnaire: subject.questionnaire, position: 0) }

        it "task has questions" do
          expect(subject.has_questions?).to be true
        end
      end

      context "when the task has no questions" do
        it "task has no questions" do
          expect(subject.has_questions?).to be false
        end
      end
    end
  end
end
