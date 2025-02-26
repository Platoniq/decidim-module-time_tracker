# frozen_string_literal: true

shared_examples "export time tracker questionnaire answers" do
  let!(:questionnaire) { create(:questionnaire, :with_questions) }
  let!(:answers) do
    questionnaire.questions.map do |question|
      create_list(:answer, 3, questionnaire:, question:, session_token: "#{rand(100)}-#{activity.id}")
    end.flatten
  end

  let(:component) { create(:time_tracker_component) }
  let(:time_tracker) { create(:time_tracker, component:) }
  let(:task) { create(:task, time_tracker:) }
  let!(:activity) { create(:activity, task:) }

  it "exports a CSV" do
    visit_component_admin

    find(".exports.dropdown").click
    perform_enqueued_jobs { click_on "CSV" }

    within ".callout.success" do
      expect(page).to have_content("in progress")
    end

    expect(last_email.subject).to include("survey_user_answers", "csv")
    expect(last_email.attachments.length).to be_positive
    expect(last_email.attachments.first.filename).to match(/^survey_user_answers.*\.zip$/)
  end

  it "exports a JSON" do
    visit_component_admin

    find(".exports.dropdown").click
    perform_enqueued_jobs { click_on "JSON" }

    within ".callout.success" do
      expect(page).to have_content("in progress")
    end

    expect(last_email.subject).to include("survey_user_answers", "json")
    expect(last_email.attachments.length).to be_positive
    expect(last_email.attachments.first.filename).to match(/^survey_user_answers.*\.zip$/)
  end
end
