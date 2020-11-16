# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeTracker do
    subject { time_tracker }

    let(:time_tracker) { create(:time_tracker) }

    it { is_expected.to be_valid }

    context "when it is persisted" do
      let!(:time_tracker) { create(:time_tracker) }

      it "creates a questionnaire and a assignee_questionnaire" do
        expect(subject.questionnaire).to be_a Decidim::Forms::Questionnaire
        expect(subject.assignee_questionnaire).to be_a Decidim::Forms::Questionnaire
      end
    end

    context "when the questionnaire has questions" do
      let!(:question) { create(:questionnaire_question, questionnaire: subject.questionnaire, position: 0) }

      it "has questions" do
        expect(subject.has_questions?).to be true
      end
    end

    context "when the questionnaire has no questions" do
      it "has no questions" do
        expect(subject.has_questions?).to be false
      end
    end
  end
end
