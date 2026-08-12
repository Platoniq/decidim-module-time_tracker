# frozen_string_literal: true

require "spec_helper"

describe "User reports page" do
  include_context "with a time_tracker"
  let(:user) { create(:user, :confirmed, organization:) }
  let(:report_path) { Decidim::EngineRouter.main_proxy(component).user_report_path }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
  end

  context "when visiting the time tracker page" do
    before do
      visit Decidim::EngineRouter.main_proxy(component).root_path
    end

    it "shows a link to the user report" do
      expect(page).to have_link("My Progress & Skills")
    end
  end

  context "when visiting the user reports page" do
    context "when user has no assignations" do
      before do
        visit report_path
      end

      it "shows a message" do
        expect(page).to have_content "You don't have any activity assignations"
      end
    end

    context "when user has assignations" do
      let!(:task) { create(:task, time_tracker:) }
      let!(:activity) { create(:activity, task:) }
      let!(:assignation) { create(:assignation, :accepted, activity:, user:) }
      let!(:assignation_pending) { create(:assignation, :pending, activity:, user:) }
      let!(:assignation_rejected) { create(:assignation, :rejected, activity:, user:) }

      it "shows the list of assignations and the time dedicated" do
        visit report_path
        expect(page).to have_content "Time dedicated so far"

        # Assignations are sorted accepted, pending, rejected (see UserReportController#assignations).
        activities = all(".time-tracker--activity")
        expect(activities.size).to eq(3)

        within activities[0] do
          expect(page).to have_i18n_content activity.description
          expect(page).to have_content "Accepted"
        end

        within activities[1] do
          expect(page).to have_i18n_content activity.description
          expect(page).to have_content "Pending"
        end

        within activities[2] do
          expect(page).to have_i18n_content activity.description
          expect(page).to have_content "Rejected"
        end
      end
    end
  end
end
