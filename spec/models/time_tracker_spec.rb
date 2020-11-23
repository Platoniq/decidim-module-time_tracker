# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeTracker do
    subject { time_tracker }

    let(:component) { create(:time_tracker_component) }
    let(:time_tracker) { create(:time_tracker, component: component, questionnaire: questionnaire) }
    let(:questionnaire) { create(:questionnaire) }

    it { is_expected.to be_valid }

    context "when it is correctly associated" do
      it "is associated with a component" do
        expect(subject.component).to eq(component)
      end

      it "is associated with a questionnaire" do
        expect(subject.questionnaire).to eq(questionnaire)
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
