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

    let(:first_task) { create(:task, time_tracker: time_tracker, name: { en: "Fix plumbing" }) }
    let(:second_task) { create(:task, time_tracker: time_tracker, name: { en: "Clean windows" }) }
    let(:first_activity) { create(:activity, task: first_task, description: { en: "Make a hole in the wall" }) }
    let(:second_activity) { create(:activity, task: first_task, description: { en: "Replace pipes" }) }
    let(:third_activity) { create(:activity, task: second_task, description: { en: "Buy cleaning products" }) }
    let!(:first_assignation) { create(:assignation, user: users.first, activity: first_activity) }
    let!(:second_assignation) { create(:assignation, user: users.second, activity: first_activity) }
    let!(:third_assignation) { create(:assignation, user: users.second, activity: second_activity) }
    let!(:fourth_assignation) { create(:assignation, user: users.third, activity: third_activity) }

    let!(:time_event) { create(:time_event, assignation: first_assignation, total_seconds: 120) }

    before do
      visit_time_tracker_admin_stats
    end

    it "shows a table with assignations" do
      within ".table-list", match: :first do
        expect(page).to have_link(translated(first_assignation.task.name), href: time_tracker_admin_task_path(first_assignation.activity.task))
        expect(page).to have_link(translated(first_assignation.activity.description), href: time_tracker_admin_assignations_path(first_assignation.activity))
        expect(page).to have_link(first_assignation.user.name, href: decidim.profile_path(first_assignation.user.nickname))
        expect(page).to have_content(first_assignation.user.email)
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
