# frozen_string_literal: true

require "spec_helper"

describe "Check-out survey" do
  include_context "with a full time_tracker"

  let(:user) { create(:user, :confirmed, organization:) }
  let(:settings) { { checkout_survey_enabled: true, data_donation_enabled: true } }

  before do
    component.update!(settings:)
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit Decidim::EngineRouter.main_proxy(component).root_path
    page.find(".time-tracker-activity-start", match: :first).click
    sleep 1
    page.find(".time-tracker-activity-stop").click
  end

  it "asks about the work and the optional data, then shows the milestone form" do
    within "#time-tracker-checkout" do
      expect(page).to have_content "You've checked out of"
      find("input[name='checkout_survey[work_nature]'][value='2']", visible: :all).click
      find("input[name='checkout_survey[work_value]'][value='4']", visible: :all).click
      find("label", text: "Caring for others").click
      find("label", text: "Not sure").click
      check "I agree to donate the information below for the policy tracker."
      select "25–34", from: "Age"
      fill_in "Ethnic or racial background (in your own words)", with: "Latina"
      find("label", text: "Gender-fluid").click
      click_on "Save"
    end

    expect(page).to have_no_css("#time-tracker-checkout[open]")
    expect(page).to have_content "Leave your mark"

    response = Decidim::TimeTracker::CheckoutResponse.last
    expect(response).to have_attributes(user:, work_nature: 2, work_value: 4, usually_paid: "not_sure", involved: %w(caring))
    expect(Decidim::TimeTracker::DataDonation.find_by(user:)).to have_attributes(consented: true, age_range: "25_34", ethnicity: "Latina",
                                                                                 gender_identities: %w(gender_fluid))
  end

  it "can be skipped" do
    within("#time-tracker-checkout") { click_on "Skip", match: :first }

    expect(page).to have_content "Leave your mark"
    expect(Decidim::TimeTracker::CheckoutResponse.count).to eq(0)
  end

  context "when the component does not ask for it" do
    let(:settings) { {} }

    it "goes straight to the milestone form" do
      expect(page).to have_no_css("#time-tracker-checkout", visible: :all)
      expect(page).to have_content "Leave your mark"
    end
  end
end
