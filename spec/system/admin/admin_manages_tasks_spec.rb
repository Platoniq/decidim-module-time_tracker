# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker" do
  include_context "with a full time_tracker"

  let(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
  end

  context "when no pending assignees" do
    before do
      visit_time_tracker_admin
    end

    it "shows activity counter next to component name in list" do
      within "a[href='#{time_tracker_admin_path}']" do
        expect(page).to have_content("Time Tracker\n#{time_tracker.activities.active.count}")
      end
    end

    it "do not show pendig assignees section" do
      within ".card-title", match: :first do
        expect(page).to have_no_content("Pending assignations")
      end
    end
  end

  context "when pending assignees" do
    let(:first_user) { create(:user, :confirmed, organization:) }
    let(:second_user) { create(:user, :confirmed, organization:) }
    let!(:pending) { create(:assignation, :pending, user: first_user, activity:) }
    let!(:rejected) { create(:assignation, :rejected, user: second_user, activity:) }

    before do
      visit_time_tracker_admin
    end

    it "shows pendig assignees section" do
      within ".item_show__header", match: :first do
        expect(page).to have_content("Pending assignations")
      end
    end

    it "show pending assignees first" do
      within ".table-list", match: :first do
        expect(page).to have_content(pending.user.name)
        expect(page).to have_content(pending.user.email)
      end
    end

    it "do not show accepted assignees" do
      within ".table-list", match: :first do
        expect(page).to have_no_content(assignation.user.name)
        expect(page).to have_no_content(assignation.user.email)
        expect(page).to have_no_content(rejected.user.name)
        expect(page).to have_no_content(rejected.user.email)
      end
    end

    it "allows to accept an individual assignation" do
      within ".assignation--pending" do
        click_on "Accept"
      end

      within ".table-list" do
        pending.reload
        expect(page).to have_no_content(pending.user.name)
        expect(page).to have_no_content(pending.user.email)
        expect(pending.status).to eq("accepted")
      end
    end

    it "allows to reject an individual assignation" do
      within ".assignation--pending" do
        click_on "Reject"
      end

      within ".table-list" do
        pending.reload
        expect(page).to have_no_content(pending.user.name)
        expect(page).to have_no_content(pending.user.email)
        expect(pending.status).to eq("rejected")
      end
    end

    it "allows to accept assignations in bulk" do
      click_on "Accept all pending assignations"
      within ".card-title", match: :first do
        expect(page).to have_no_content("Pending assignations")
      end

      within ".table-list" do
        pending.reload
        expect(page).to have_no_content(pending.user.name)
        expect(page).to have_no_content(pending.user.email)
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
