# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateTimeTracker do
    subject { described_class.new(component) }

    let(:organization) { create :organization }
    let(:user) { create :user, :admin, :confirmed, organization: organization }
    let(:participatory_process) { create :participatory_process, organization: organization }
    let(:component) { create :time_tracker_component, participatory_space: participatory_process }

    context "when the save command is not successful" do
      let(:component) { nil }

      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the save command is successful" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new time_tracker for the organization" do
        expect { subject.call }.to change(Decidim::TimeTracker::TimeTracker, :count).by(1)
      end

      it "creates two associated questionnaires" do
        expect { subject.call }.to change(Decidim::Forms::Questionnaire, :count).by(2)
      end
    end

    describe "activity questionnaire seeds" do
      default_activity_questionnaire_seeds = Decidim::TimeTracker.default_activity_questionnaire_seeds
      custom_activity_questionnaire_seeds = {
        tos: "TOS",
        title: "A questionnaire",
        description: { en: "This is a questionnaire" },
        questions: [
          { question_type: "short_answer", body: "Question 1" },
          { question_type: "single_option", body: { en: "Question 2" }, answer_options: [{ body: "Answer Option 1", free_text: true }] }
        ]
      }

      context "when time_tracker_questionnaire_seeds config is the default" do
        before do
          Decidim::TimeTracker.default_activity_questionnaire_seeds = default_activity_questionnaire_seeds
          subject.call
        end

        it "has questions" do
          expect(subject.time_tracker.has_questions?).to be true
          expect(subject.questionnaire.title["en"]).to eq "How do you perceive this task?"
          expect(subject.questionnaire.questions.count).to eq 3
          expect(subject.questionnaire.questions.first.question_type).to eq "single_option"
          expect(subject.questionnaire.questions.first.position).to eq 1
          expect(subject.questionnaire.questions.first.body["en"]).to eq "How important do you think this task is?"
          expect(subject.questionnaire.questions.second.question_type).to eq "separator"
          expect(subject.questionnaire.questions.second.position).to eq 2
          expect(subject.questionnaire.questions.second.body).to be_nil
          expect(subject.questionnaire.questions.third.question_type).to eq "single_option"
          expect(subject.questionnaire.questions.third.position).to eq 3
          expect(subject.questionnaire.questions.third.body["en"]).to eq "Who do you think usually perform this task?"
        end
      end

      context "when time_tracker_questionnaire_seeds config is nil" do
        before do
          Decidim::TimeTracker.default_activity_questionnaire_seeds = nil
          subject.call
        end

        it "has no questions" do
          expect(subject.time_tracker.has_questions?).to be false
          expect(subject.questionnaire.title).to be_nil
          expect(subject.questionnaire.questions.count).to eq 0
        end
      end

      context "when time_tracker_questionnaire_seeds config is customized" do
        before do
          Decidim::TimeTracker.default_activity_questionnaire_seeds = custom_activity_questionnaire_seeds
          subject.call
        end

        it "has questions" do
          expect(subject.time_tracker.has_questions?).to be true
          expect(subject.questionnaire.title["en"]).to eq(custom_activity_questionnaire_seeds[:title])
          expect(subject.questionnaire.tos["en"]).to eq(custom_activity_questionnaire_seeds[:tos])
          expect(subject.questionnaire.description["en"]).to eq(custom_activity_questionnaire_seeds[:description][:en])
          expect(subject.questionnaire.questions.first.body["en"]).to eq(custom_activity_questionnaire_seeds[:questions][0][:body])
          expect(subject.questionnaire.questions.second.answer_options.first.body["en"]).to eq(custom_activity_questionnaire_seeds[:questions][1][:answer_options][0][:body])
          expect(subject.questionnaire.questions.second.answer_options.first.free_text).to be true
        end
      end
    end

    describe "assignee questionnaire seeds" do
      default_assignee_questionnaire_seeds = Decidim::TimeTracker.default_assignee_questionnaire_seeds
      custom_assignee_questionnaire_seeds = {
        tos: "TOS",
        title: "A questionnaire",
        description: { en: "This is a questionnaire" },
        questions: [
          { question_type: "short_answer", body: "Question 1" },
          { question_type: "single_option", body: { en: "Question 2" }, answer_options: [{ body: "Answer Option 1", free_text: true }] }
        ]
      }
      context "when time_tracker_questionnaire_seeds config is the default" do
        before do
          Decidim::TimeTracker.default_assignee_questionnaire_seeds = default_assignee_questionnaire_seeds
          subject.call
        end

        it "has assignee questions" do
          expect(subject.time_tracker.has_assignee_questions?).to be true
          expect(subject.assignee_questionnaire.title["en"]).to eq "Terms of use and demographic data"
          expect(subject.assignee_questionnaire.questions.count).to eq 3
          expect(subject.assignee_questionnaire.questions.first.question_type).to eq "single_option"
          expect(subject.assignee_questionnaire.questions.first.position).to eq 1
          expect(subject.assignee_questionnaire.questions.first.body["en"]).to eq "Which gender do you identify with?"
          expect(subject.assignee_questionnaire.questions.second.question_type).to eq "separator"
          expect(subject.assignee_questionnaire.questions.second.position).to eq 2
          expect(subject.assignee_questionnaire.questions.second.body).to be_nil
          expect(subject.assignee_questionnaire.questions.third.question_type).to eq "single_option"
          expect(subject.assignee_questionnaire.questions.third.position).to eq 3
          expect(subject.assignee_questionnaire.questions.third.body["en"]).to eq "What is your age?"
        end
      end

      context "when time_tracker_questionnaire_seeds config is nil" do
        before do
          Decidim::TimeTracker.default_assignee_questionnaire_seeds = nil
          subject.call
        end

        it "has no assignee questions" do
          expect(subject.time_tracker.has_assignee_questions?).to be false
          expect(subject.assignee_questionnaire.title).to be_nil
          expect(subject.assignee_questionnaire.questions.count).to eq 0
        end
      end

      context "when time_tracker_questionnaire_seeds config is customized" do
        before do
          Decidim::TimeTracker.default_assignee_questionnaire_seeds = custom_assignee_questionnaire_seeds
          subject.call
        end

        it "has assignee questions" do
          expect(subject.time_tracker.has_assignee_questions?).to be true
          expect(subject.assignee_questionnaire.title["en"]).to eq(custom_assignee_questionnaire_seeds[:title])
          expect(subject.assignee_questionnaire.tos["en"]).to eq(custom_assignee_questionnaire_seeds[:tos])
          expect(subject.assignee_questionnaire.description["en"]).to eq(custom_assignee_questionnaire_seeds[:description][:en])
          expect(subject.assignee_questionnaire.questions.first.body["en"]).to eq(custom_assignee_questionnaire_seeds[:questions][0][:body])
          expect(subject.assignee_questionnaire.questions.second.answer_options.first.body["en"]).to eq(custom_assignee_questionnaire_seeds[:questions][1][:answer_options][0][:body])
          expect(subject.assignee_questionnaire.questions.second.answer_options.first.free_text).to be true
        end
      end
    end
  end
end
