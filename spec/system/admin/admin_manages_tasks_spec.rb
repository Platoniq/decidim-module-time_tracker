# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker", type: :system do
  include_context "with a full time_tracker"

  let(:user) { create :user, :admin, organization: organization }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
  end

  context "when no pending assignees" do
    before do
      visit_time_tracker_admin
    end

    it "shows activity counter next to component name in list" do
      expect(page).to have_link "Time Tracker #{time_tracker.activities.active.count}", href: time_tracker_admin_path
    end

    it "do not show pendig assignees section" do
      within ".card-title", match: :first do
        expect(page).not_to have_content("Pending assignations")
      end
    end
  end

  context "when pending assignees" do
    let(:user1) { create(:user, :confirmed, organization: organization) }
    let(:user2) { create(:user, :confirmed, organization: organization) }
    let!(:pending) { create(:assignation, :pending, user: user1, activity: activity) }
    let!(:rejected) { create(:assignation, :rejected, user: user2, activity: activity) }

    before do
      visit_time_tracker_admin
    end

    it "shows pendig assignees section" do
      within ".card-title", match: :first do
        expect(page).to have_content("Pending assignations")
      end
    end

    it "show pending assignees first" do
      within ".process-content" do
        expect(page).to have_content(pending.user.name)
        expect(page).to have_content(pending.user.email)
      end
    end

    it "do not show accepted assignees" do
      within ".process-content" do
        expect(page).not_to have_content(assignation.user.name)
        expect(page).not_to have_content(assignation.user.email)
        expect(page).not_to have_content(rejected.user.name)
        expect(page).not_to have_content(rejected.user.email)
      end
    end

    it "allows to accept an individual assignation" do
      within ".assignation--pending" do
        click_link "Accept"
      end

      within ".process-content" do
        pending.reload
        expect(page).not_to have_content(pending.user.name)
        expect(page).not_to have_content(pending.user.email)
        expect(pending.status).to eq("accepted")
      end
    end

    it "allows to reject an individual assignation" do
      within ".assignation--pending" do
        click_link "Reject"
      end

      within ".process-content" do
        pending.reload
        expect(page).not_to have_content(pending.user.name)
        expect(page).not_to have_content(pending.user.email)
        expect(pending.status).to eq("rejected")
      end
    end

    it "allows to accept assignations in bulk" do
      click_link "Accept all pending assignations"
      within ".card-title", match: :first do
        expect(page).not_to have_content("Pending assignations")
      end

      within ".process-content" do
        pending.reload
        expect(page).not_to have_content(pending.user.name)
        expect(page).not_to have_content(pending.user.email)
        expect(pending.status).to eq("accepted")
      end
    end
  end

  def visit_time_tracker_admin
    visit time_tracker_admin_path
  end

  def time_tracker_admin_path
    Decidim::EngineRouter.admin_proxy(component).root_path
  end
end
