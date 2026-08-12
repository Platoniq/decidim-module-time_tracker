# frozen_string_literal: true

require "spec_helper"

describe "Activity page" do
  include_context "with a time_tracker"

  let(:user) { create(:user, :confirmed, organization:) }
  let(:task) { create(:task, time_tracker:) }
  let(:activity) { create(:activity, task:) }
  let(:participant) { create(:user, :confirmed, organization:) }
  let!(:assignation) { create(:assignation, :accepted, activity:, user: participant) }
  let!(:milestone) { create(:milestone, activity:, user: participant) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  def activity_path
    Decidim::EngineRouter.main_proxy(component).task_activity_path(task, activity)
  end

  it "shows the activity details" do
    visit activity_path

    expect(page).to have_i18n_content(activity.description)
    expect(page).to have_i18n_content(task.name)
    expect(page).to have_content("1 participant")
    expect(page).to have_content(milestone.title)
  end

  it "links participants to their profile" do
    visit activity_path

    expect(page).to have_css("a[href*='/profiles/#{participant.nickname}']")
  end

  it "is reachable from the activity list" do
    visit Decidim::EngineRouter.main_proxy(component).root_path

    within first(".card--list__heading") do
      click_on activity.description["en"]
    end

    expect(page).to have_current_path(activity_path)
  end
end
