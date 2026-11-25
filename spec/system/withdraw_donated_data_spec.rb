# frozen_string_literal: true

require "spec_helper"

describe "Withdrawing donated data" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let!(:donation) { create(:data_donation, user:, ethnicity: "Latina") }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim.my_voluntary_work_path
  end

  it "shows what was donated and deletes it on request" do
    within "#donated-data" do
      expect(page).to have_content "Latina"
      accept_confirm { click_on "Withdraw and delete my data" }
    end

    expect(page).to have_content "Your donated data has been deleted."
    expect(Decidim::TimeTracker::DataDonation.where(user:)).to be_empty
  end
end
