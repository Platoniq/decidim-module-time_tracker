# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker stats", type: :system do
  include_context "with a time_tracker"

  let(:user) { create :user, :admin, organization: organization }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
  end

  context "when there are assignations" do
    let(:users) { create_list(:user, 3, :confirmed, organization: organization) }

    let!(:tasks) { create_list(:task, 2, time_tracker: time_tracker) }
    let!(:activities) { tasks.map { |task| create_list(:activity, 2, task: task) }.flatten }
    let!(:assignations) do 
      [
        create(:assignation, user: users.first,  activity: activities.first),
        create(:assignation, user: users.second, activity: activities.first),
        create(:assignation, user: users.second, activity: activities.second),
        create(:assignation, user: users.second, activity: activities.third),
        create(:assignation, user: users.third,  activity: activities.first),
        create(:assignation, user: users.third,  activity: activities.last)
      ]
    end

    let!(:time_event) { create(:time_event, assignation: assignations.first, total_seconds: 120) }

    before do
      visit_time_tracker_admin_stats
    end

    it "shows a table with assignations" do
      assignation = assignations.first
      within ".table-list", match: :first do
        within "tbody tr", match: :first do
          expect(page).to have_link(assignation.task.name["en"], href: time_tracker_admin_task_path(assignation.activity.task))
          expect(page).to have_link(assignation.activity.description["en"], href: time_tracker_admin_assignations_path(assignation.activity))
          expect(page).to have_link(assignation.user.name, href: decidim.profile_path(assignation.user.nickname))
          expect(page).to have_content(assignation.user.email)
          expect(page).to have_content("00h02m00s")
        end
      end
    end
  end

  def visit_time_tracker_admin_stats
    visit time_tracker_admin_stats_path
  end

  def time_tracker_admin_stats_path
    Decidim::EngineRouter.admin_proxy(component).stats_path
  end

  def time_tracker_admin_assignations_path(activity)
    Decidim::EngineRouter.admin_proxy(component).task_activity_assignations_path(activity_id: activity.id, task_id: activity.task.id)
  end
  
  def time_tracker_admin_task_path(task)
    Decidim::EngineRouter.admin_proxy(component).edit_task_path(task)
  end
end
