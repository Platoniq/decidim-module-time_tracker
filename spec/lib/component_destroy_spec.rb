# frozen_string_literal: true

require "spec_helper"

describe "Destroying a time tracker component" do # rubocop:disable RSpec/DescribeClass
  subject(:run_hooks) { component.manifest.run_hooks(:before_destroy, component) }

  let(:component) { create(:time_tracker_component) }
  let(:time_tracker) { Decidim::TimeTracker::TimeTracker.find_by(component:) }

  before { Decidim::TimeTracker::Admin::CreateTimeTracker.call(component) }

  context "when the time tracker is empty" do
    it "removes it with both of its questionnaires" do
      questionnaire_ids = [time_tracker.questionnaire.id, time_tracker.assignee_questionnaire.id]

      expect { run_hooks }.not_to raise_error

      expect(Decidim::TimeTracker::TimeTracker.where(component:)).to be_empty
      expect(Decidim::TimeTracker::AssigneeData.where(time_tracker:)).to be_empty
      expect(Decidim::Forms::Questionnaire.where(id: questionnaire_ids)).to be_empty
    end
  end

  context "when the time tracker holds tasks" do
    before { create(:task, time_tracker:) }

    it "refuses, and keeps everything" do
      expect { run_hooks }.to raise_error(StandardError, /resources associated/)
      expect(time_tracker.reload).to be_present
    end
  end

  context "when someone has answered one of its questionnaires" do
    before { create(:response, questionnaire: time_tracker.assignee_questionnaire, question: create(:questionnaire_question, questionnaire: time_tracker.assignee_questionnaire)) }

    it "refuses, and keeps the answers" do
      expect { run_hooks }.to raise_error(StandardError, /resources associated/)
      expect(time_tracker.assignee_questionnaire.responses).to exist
    end
  end

  context "when there is no time tracker for the component" do
    before { time_tracker.assignee_data.destroy! && time_tracker.destroy! }

    it "does nothing" do
      expect { run_hooks }.not_to raise_error
    end
  end
end
