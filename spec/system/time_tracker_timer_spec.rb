# frozen_string_literal: true

require "spec_helper"

describe "Time tracker page", type: :system do
  let(:organization) { create :organization }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:participatory_space) { create(:participatory_process, organization: organization) }
  let(:component) { create :time_tracker_component, participatory_space: participatory_space }
  let!(:time_tracker) { create :time_tracker, component: component }
  let!(:task) { create(:task, time_tracker: time_tracker) }
  let!(:activity) { create(:activity, task: task) }
  let!(:assignation) { create(:assignation, user: user, activity: activity) }
  let!(:tos_acceptance) { Decidim::TimeTracker::TosAcceptance.create!(assignee: Decidim::TimeTracker::Assignee.for(user), time_tracker: time_tracker) }

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
      expect(page).not_to have_selector ".time-tracker-activity-start"
      expect(page).to have_selector ".time-tracker-activity-stop"
      expect(page).to have_selector ".time-tracker-activity-pause"
    end

    it "pauses the timer" do
      expect(page).not_to have_content "0h0m0s"
      page.find(".time-tracker-activity-pause").click
      expect(page).not_to have_selector ".time-tracker-activity-pause"
      expect(page).to have_selector ".time-tracker-activity-stop"
      expect(page).to have_selector ".time-tracker-activity-start"
    end

    context "when stopping the timer" do
      before do
        page.find(".time-tracker-activity-stop").click
      end

      it "stops the timer" do
        expect(page).not_to have_selector ".time-tracker-activity-stop"
        expect(page).not_to have_selector ".time-tracker-activity-pause"
        expect(page).to have_selector ".time-tracker-activity-start"
        expect(page).to have_content "Leave your mark"

        within ".milestone" do
          expect(page).to have_button "Save"
        end
      end

      it "allows submitting a milestone", processing_uploads_for: Decidim::AttachmentUploader do
        within ".new_milestone" do
          fill_in "What have you done?", with: "I saved the world from chaos!"
          fill_in "Description", with: "Specs are the only thing that separate us from barbaric coding"
          attach_file :milestone_attachment_file, Decidim::Dev.asset("city.jpeg")
          click_button "Save"
        end

        expect(page).to have_current_path milestones_path(user)
        expect(page).to have_content "I saved the world"
        expect(page).to have_link "Back to activities", href: time_tracker_path
      end
    end

    context "when starts another timer" do
      let!(:activity2) { create(:activity, task: task) }
      let!(:assignation2) { create(:assignation, user: user, activity: activity2) }

      it "has different counters" do
        expect(page).to have_selector(".time-tracker-activity-start", count: 2)
        expect(page).not_to have_selector(".time-tracker-activity-stop")
        expect(page).not_to have_selector(".time-tracker-activity-pause")
      end

      it "has one counter started, one stopped" do
        expect(page).to have_content("0h0m0s", count: 1)
        expect(page).to have_content("0h0m", count: 2)
        within ".time-tracker-activity", match: :first do
          expect(page).not_to have_content("0h0m0s")
        end
      end

      it "stops runninng counters" do
        within ".time-tracker-activity", match: :first do
          page.find(".time-tracker-activity-start").last.click
          sleep 1
        end

        expect(page).not_to have_content("0h0m0s")

        within ".time-tracker-activity", match: :first do
          expect(page).to have_selector(".time-tracker-activity-play")
          expect(page).to have_selector(".time-tracker-activity-stop")
          expect(page).not_to have_selector(".time-tracker-activity-pause")
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
