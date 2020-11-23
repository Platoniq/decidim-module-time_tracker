# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateTimeTracker do
    let(:subject) { described_class.new(component) }

    let(:organization) { create :organization }
    let(:user) { create :user, :admin, :confirmed, organization: organization }
    let(:participatory_process) { create :participatory_process, organization: organization }
    let(:component) { create :time_tracker_component, participatory_space: participatory_process }

    default_questionnaire_seeds = Decidim::TimeTracker.default_questionnaire_seeds
    custom_questionnaire_seeds = {
      tos: "TOS",
      title: "A questionnaire",
      description: { en: "This is a questionnaire" },
      questions: [
        { question_type: "short_answer", body: "Question 1" },
        { question_type: "single_option", body: { en: "Question 2" }, answer_options: [{ body: "Answer Option 1", free_text: true }] }
      ]
    }

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
        expect { subject.call }.to change { Decidim::TimeTracker::TimeTracker.count }.by(1)
      end

      it "creates an associated questionnaire" do
        expect { subject.call }.to change { Decidim::Forms::Questionnaire.count }.by(1)
      end
    end

    context "when time_tracker_questionnaire_seeds config is the default" do
      before do
        Decidim::TimeTracker.default_questionnaire_seeds = default_questionnaire_seeds
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
        expect(subject.questionnaire.questions.second.body).to eq nil
        expect(subject.questionnaire.questions.third.question_type).to eq "single_option"
        expect(subject.questionnaire.questions.third.position).to eq 3
        expect(subject.questionnaire.questions.third.body["en"]).to eq "Who do you think usually perform this task?"
      end
    end

    context "when time_tracker_questionnaire_seeds config is nil" do
      before do
        Decidim::TimeTracker.default_questionnaire_seeds = nil
      end

      it "has no questions" do
        expect(subject.time_tracker.has_questions?).to be false
        expect(subject.questionnaire.title).to eq nil
        expect(subject.questionnaire.questions.count).to eq 0
      end
    end

    context "when time_tracker_questionnaire_seeds config is customized" do
      before do
        Decidim::TimeTracker.default_questionnaire_seeds = custom_questionnaire_seeds
      end

      it "has questions" do
        expect(subject.time_tracker.has_questions?).to be true
        expect(subject.questionnaire.title["en"]).to eq(custom_questionnaire_seeds[:title])
        expect(subject.questionnaire.tos["en"]).to eq(custom_questionnaire_seeds[:tos])
        expect(subject.questionnaire.description["en"]).to eq(custom_questionnaire_seeds[:description][:en])
        expect(subject.questionnaire.questions.first.body["en"]).to eq(custom_questionnaire_seeds[:questions][0][:body])
        expect(subject.questionnaire.questions.second.answer_options.first.body["en"]).to eq(custom_questionnaire_seeds[:questions][1][:answer_options][0][:body])
        expect(subject.questionnaire.questions.second.answer_options.first.free_text).to eq true
      end
    end
  end
end
