# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Task do
    subject { task }

    let(:component) { create(:time_tracker_component) }
    let(:first_activity) { create(:activity, :with_assignees, start_date: Time.zone.now, end_date: 1.day.from_now) }
    let(:middle_activity) { create(:activity, :with_assignees, start_date: Time.zone.now, end_date: 2.days.from_now) }
    let(:last_activity) { create(:activity, :with_assignees, start_date: 1.day.from_now, end_date: 2.days.from_now) }
    let(:activities) { [first_activity, middle_activity, last_activity] }
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

    describe "#starts_at" do
      it "returns the start_date of the activity that starts the earliest" do
        expect(subject.starts_at).to eq(first_activity.start_date)
      end
    end

    describe "#ends_at" do
      it "returns the end_date of the activity that ends the latest" do
        expect(subject.ends_at).to eq(last_activity.end_date)
      end
    end

    describe "#assignees_count" do
      context "without a filter parameter" do
        it "returns the accepted assignees count" do
          expect(subject.assignees_count).to eq(subject.assignees_count(filter: :accepted))
        end
      end
    end

    context "when the filter parameter is provided" do
      context "when its value is :pending" do
        it "returns the sum of all the activities's pending assignees count" do
          expect(subject.assignees_count(filter: :pending)).to eq(activities.map { |a| a.assignees.pending.count }.sum)
        end
      end

      context "when its value is :accepted" do
        it "returns the sum of all the activities's accepted assignees count" do
          expect(subject.assignees_count(filter: :accepted)).to eq(activities.map { |a| a.assignees.accepted.count }.sum)
        end
      end

      context "when its value is :rejected" do
        it "returns the sum of all the activities's rejected assignees count" do
          expect(subject.assignees_count(filter: :rejected)).to eq(activities.map { |a| a.assignees.rejected.count }.sum)
        end
      end

      context "when its value is not one of [:pending, :accepted, :rejected]" do
        it "raises an error" do
          expect { subject.assignees_count(filter: :other) }.to raise_error(NoMethodError)
        end
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

    context "when time_tracker_questionnaire_seeds config is defined" do
      it "has questions" do
        Rails.application.config.time_tracker_questionnaire_seeds = {
          tos: { en: "TOS" },
          title: { en: "Questionnaire" },
          description: { en: "This is a questionnaire" },
          questions: [
            { question_type: "short_answer", body: { en: "Question 1" } },
            { question_type: "single_option", body: { en: "Question 2" }, answer_options: [{ body: { en: "Answer Option 1" }, free_text: true }] }
          ]
        }

        expect(subject.has_questions?).to be true
        expect(subject.questionnaire.title["en"]).to eq "Questionnaire"
        expect(subject.questionnaire.questions.first.body["en"]).to eq "Question 1"
        expect(subject.questionnaire.questions.second.answer_options.first.body["en"]).to eq "Answer Option 1"
        expect(subject.questionnaire.questions.second.answer_options.first.free_text).to eq true
      end
    end
  end
end
