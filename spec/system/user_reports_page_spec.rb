# frozen_string_literal: true

require "spec_helper"

describe "User reports page", type: :system do
  let(:organization) { create :organization }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:participatory_space) { create(:participatory_process, organization: organization) }
  let(:component) { create :time_tracker_component, participatory_space: participatory_space }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
  end

  context "when visiting user account page" do
    before do
      visit decidim.account_path
    end

    it "shows a link to user reports page" do
      expect(page).to have_link("My voluntary work")
    end
  end

  context "when visiting the user reports page" do
    context "when user has no assignations" do
      before do
        visit decidim_time_tracker.root_path
      end

      it "shows a message" do
        expect(page).to have_content "You don't have any activity assignations"
      end
    end

    context "when user has assignations" do
      let!(:task) { create :task, component: component }
      let!(:activity) { create :activity, task: task }
      let!(:assignee) { create :assignee, :accepted, activity: activity, user: user }
      let!(:assignee_pending) { create :assignee, :pending, activity: activity, user: user }
      let!(:assignee_rejected) { create :assignee, :rejected, activity: activity, user: user }

      it "shows the list of assignations and the time dedicated" do
        visit decidim_time_tracker.root_path
        expect(page).to have_content "Time dedicated so far"

        within ".card--list__item:nth-child(1)" do
          expect(page).to have_link activity.description
          expect(page).to have_content "Accepted"
        end

        within ".card--list__item:nth-child(2)" do
          expect(page).to have_link activity.description
          expect(page).to have_content "Pending"
        end

        within ".card--list__item:nth-child(3)" do
          expect(page).to have_link activity.description
          expect(page).to have_content "Rejected"
        end
      end
    end
  end
end
