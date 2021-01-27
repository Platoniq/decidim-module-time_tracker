# frozen_string_literal: true

require "spec_helper"

describe "Milestones page", type: :system do
  include_context "with a time_tracker"

  let!(:user) { create :user, :confirmed, organization: organization, nickname: "timmy" }
  let(:task) { create :task, time_tracker: time_tracker }
  let(:activity) { create :activity, task: task }
  let!(:assignation) { create :assignation, activity: activity, user: user }
  let!(:milestones) { create_list :milestone, 3, activity: activity, user: user }
  let!(:tos_acceptance) { create :tos_acceptance, assignee: Decidim::TimeTracker::Assignee.for(user), time_tracker: time_tracker }
  let!(:time_events) { create_list(:time_event, 2, activity: activity, assignation: assignation, total_seconds: 10) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit_milestones
  end

  it "shows total time dedicated" do
    within ".time-tracker--clock" do
      expect(page).to have_content("0h0m20s")
    end
  end

  it "shows when user joined" do
    expect(page).to have_content(tos_acceptance.created_at.strftime("%d %b %Y"))
  end

  it "shows when user last worked" do
    expect(page).to have_content(milestones.last.created_at.strftime("%d %b %Y"))
  end

  it "shows milestones" do
    expect(page).to have_content("#{user.name}'s activity")
    expect(page).to have_link(user.name, href: decidim.profile_path(nickname: "timmy"))
    expect(page).to have_selector(".card.card--milestone", count: 3)

    within ".card.card--milestone", match: :first do
      expect(page).to have_content(milestones.first.title)
      expect(page).to have_content(milestones.first.description)
    end
  end

  it "shows back link" do
    expect(page).to have_link "Back to activities", href: time_tracker_path
  end

  def visit_milestones
    visit milestones_path
  end

  def milestones_path
    Decidim::EngineRouter.main_proxy(component).milestones_path(nickname: "timmy")
  end

  def time_tracker_path
    Decidim::EngineRouter.main_proxy(component).root_path
  end
end
