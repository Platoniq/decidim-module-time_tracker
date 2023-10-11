# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker stats", type: :system do
  include_context "with a time_tracker"

  let(:resource_controller) { Decidim::TimeTracker::Admin::StatsController }
  let(:user) { create :user, :admin, :confirmed, organization: organization }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
  end

  context "when there are assignations" do
    let(:users) { create_list(:user, 3, :confirmed, organization: organization) }

    let(:task_1) { create(:task, time_tracker: time_tracker, name: { en: "Fix plumbing" }) }
    let(:task_2) { create(:task, time_tracker: time_tracker, name: { en: "Clean windows" }) }
    let(:activity_1) { create(:activity, task: task_1, description: { en: "Make a hole in the wall" }) }
    let(:activity_2) { create(:activity, task: task_1, description: { en: "Replace pipes" }) }
    let(:activity_3) { create(:activity, task: task_2, description: { en: "Buy cleaning products" }) }
    let!(:assignation_1) { create(:assignation, user: users.first, activity: activity_1) }
    let!(:assignation_2) { create(:assignation, user: users.second, activity: activity_1) }
    let!(:assignation_3) { create(:assignation, user: users.second, activity: activity_2) }
    let!(:assignation_4) { create(:assignation, user: users.third, activity: activity_3) }

    let!(:time_event) { create(:time_event, assignation: assignation_1, total_seconds: 120) }

    before do
      visit_time_tracker_admin_stats
    end

    it "shows a table with assignations" do
      within ".table-list", match: :first do
        expect(page).to have_link(translated(assignation_1.task.name), href: time_tracker_admin_task_path(assignation_1.activity.task))
        expect(page).to have_link(translated(assignation_1.activity.description), href: time_tracker_admin_assignations_path(assignation_1.activity))
        expect(page).to have_link(assignation_1.user.name, href: decidim.profile_path(assignation_1.user.nickname))
        expect(page).to have_content(assignation_1.user.email)
        expect(page).to have_content("00h02m00s")
      end
    end

    include_context "with filterable context" do
      let!(:filterable_concern) { "Decidim::TimeTracker::Admin::FilterableAssignations".constantize }
      let!(:factory_name) { :assignation }

      context "when filtering collection by task" do
        it_behaves_like "a filtered collection", options: "Task", filter: "Fix plumbing" do
          let(:in_filter) { users.first.email }
          let(:not_in_filter) { users.third.email }
        end
      end

      context "when filtering collection by activity" do
        it_behaves_like "a filtered collection", options: "Activity", filter: "Replace pipes" do
          let(:in_filter) { users.second.email }
          let(:not_in_filter) { users.third.email }
        end
      end

      %w(name email).each do |field|
        it "can be searched by user #{field}" do
          search_by_text(users.first.send(field))

          expect(page).to have_content(users.first.send(field))
          expect(page).not_to have_content(users.second.send(field))
        end
      end

      it "can be searched by user nickname" do
        search_by_text(users.first.nickname)

        expect(page).to have_content(users.first.name)
        expect(page).not_to have_content(users.second.name)
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
