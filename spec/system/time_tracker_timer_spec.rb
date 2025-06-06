# frozen_string_literal: true

require "spec_helper"

describe "Time tracker page" do
  include_context "with a full time_tracker"

  let(:user) { create(:user, :confirmed, organization:) }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
    visit_time_tracker
  end

  it "has a timer" do
    expect(page).to have_content "0h0m0s"
  end

  context "when user counts time" do
    before do
      page.find(".time-tracker-activity-start", match: :first).click
      sleep 1
    end

    it "starts the timer" do
      expect(page).to have_no_css ".time-tracker-activity-start"
      expect(page).to have_css ".time-tracker-activity-stop"
      expect(page).to have_css ".time-tracker-activity-pause"
    end

    it "pauses the timer" do
      expect(page).to have_no_content "0h0m0s"
      page.find(".time-tracker-activity-pause").click
      expect(page).to have_no_css ".time-tracker-activity-pause"
      expect(page).to have_css ".time-tracker-activity-start"
    end

    context "when stopping the timer" do
      before do
        page.find(".time-tracker-activity-stop").click
      end

      it "stops the timer" do
        expect(page).to have_no_css ".time-tracker-activity-stop"
        expect(page).to have_no_css ".time-tracker-activity-pause"
        expect(page).to have_css ".time-tracker-activity-start"
        expect(page).to have_content "Leave your mark"

        within ".milestone" do
          expect(page).to have_button "Save"
        end
      end

      it "allows submitting a milestone", processing_uploads_for: Decidim::AttachmentUploader do
        within ".new_milestone" do
          fill_in "What have you done?", with: "I saved the world from chaos!"
          fill_in "Description", with: "Specs are the only thing that separate us from barbaric coding"
        end
        dynamically_attach_file(:milestone_attachment_file, Decidim::Dev.asset("city.jpeg"))
        within ".new_milestone" do
          click_on "Save"
        end

        expect(page).to have_current_path milestones_path(user)
        expect(page).to have_content "I saved the world"
        expect(page).to have_link "Back to activities", href: time_tracker_path
      end
    end

    context "when starts another timer" do
      let!(:activity2) { create(:activity, task:) }
      let!(:assignation2) { create(:assignation, user:, activity: activity2) }

      before do
        # renew page
        visit_time_tracker
      end

      it "has different counters" do
        expect(page).to have_css(".time-tracker-activity-start", count: 1)
        expect(page).to have_css(".time-tracker-activity-stop", count: 1)
        expect(page).to have_css(".time-tracker-activity-pause", count: 1)
      end

      it "has one counter started, one stopped" do
        expect(page).to have_content("0h0m0s", count: 1)
        expect(page).to have_content("0h0m", count: 2)
        within ".time-tracker-activity", match: :first do
          expect(page).to have_no_content("0h0m0s")
        end
      end

      it "stops runninng counters" do
        page.find(".time-tracker-activity-start").click
        sleep 1
        expect(page).to have_no_content("0h0m0s")
        within ".time-tracker-activity", match: :first do
          expect(page).to have_css(".time-tracker-activity-start")
          expect(page).to have_no_css(".time-tracker-activity-pause")
        end
      end
    end
  end

  def visit_time_tracker
    visit time_tracker_path
  end

  def time_tracker_path
    Decidim::EngineRouter.main_proxy(component).root_path
  end

  def milestones_path(user)
    Decidim::EngineRouter.main_proxy(component).milestones_path(nickname: user.nickname)
  end
end
