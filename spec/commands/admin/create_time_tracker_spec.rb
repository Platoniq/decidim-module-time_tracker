# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateTimeTracker do
    let(:subject) { described_class.new(component) }

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
        expect { subject.call }.to change { Decidim::TimeTracker::TimeTracker.count }.by(1)
      end

      it "creates an associated questionnaire" do
        expect { subject.call }.to change { Decidim::Forms::Questionnaire.count }.by(1)
      end
    end

    context "when time_tracker_questionnaire_seeds config is defined" do
      before do
        Decidim::TimeTracker.default_questionnaire_seeds = {
          tos: { en: "TOS" },
          title: { en: "Questionnaire" },
          description: { en: "This is a questionnaire" },
          questions: [
            { question_type: "short_answer", body: { en: "Question 1" } },
            { question_type: "single_option", body: { en: "Question 2" }, answer_options: [{ body: { en: "Answer Option 1" }, free_text: true }] }
          ]
        }
      end

      it "has questions" do
        expect(subject.time_tracker.has_questions?).to be true
        expect(subject.questionnaire.title["en"]).to eq "Questionnaire"
        expect(subject.questionnaire.questions.first.body["en"]).to eq "Question 1"
        expect(subject.questionnaire.questions.second.answer_options.first.body["en"]).to eq "Answer Option 1"
        expect(subject.questionnaire.questions.second.answer_options.first.free_text).to eq true
      end
    end
  end
end
