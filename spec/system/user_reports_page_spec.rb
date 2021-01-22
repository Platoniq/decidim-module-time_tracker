# frozen_string_literal: true

require "spec_helper"

describe "User reports page", type: :system do
  include_context "with a time_tracker"
  let(:user) { create :user, :confirmed, organization: organization }

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
      let!(:task) { create :task, time_tracker: time_tracker }
      let!(:activity) { create :activity, task: task }
      let!(:assignation) { create :assignation, :accepted, activity: activity, user: user }
      let!(:assignation_pending) { create :assignation, :pending, activity: activity, user: user }
      let!(:assignation_rejected) { create :assignation, :rejected, activity: activity, user: user }

      it "shows the list of assignations and the time dedicated" do
        visit decidim_time_tracker.root_path
        expect(page).to have_content "Time dedicated so far"

        within ".time-tracker--activity:nth-child(1) .card--list__item" do
          expect(page).to have_i18n_content activity.description
          expect(page).to have_content "Accepted"
        end

        within ".time-tracker--activity:nth-child(2) .card--list__item" do
          expect(page).to have_i18n_content activity.description
          expect(page).to have_content "Pending"
        end

        within ".time-tracker--activity:nth-child(3) .card--list__item" do
          expect(page).to have_i18n_content activity.description
          expect(page).to have_content "Rejected"
        end
      end
    end
  end
end
