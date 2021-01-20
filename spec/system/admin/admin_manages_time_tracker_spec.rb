# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker", type: :system do
  let(:organization) { create :organization }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:participatory_space) { create(:participatory_process, organization: organization) }
  let(:component) { create :time_tracker_component, participatory_space: participatory_space }
  let!(:time_tracker) { create :time_tracker, component: component }
  let!(:tasks) { create_list :task, 3, time_tracker: time_tracker }
  let!(:activities) { tasks.map { |task| create_list :activity, 3, task: task }.flatten }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
    visit_time_tracker_admin
  end

  it "shows activity counter next to component name in list" do
    expect(page).to have_link "Time Tracker #{activities.count}", href: time_tracker_admin_path
  end

  def visit_time_tracker_admin
    visit time_tracker_admin_path
  end

  def time_tracker_admin_path
    Decidim::EngineRouter.admin_proxy(component).root_path
  end
end
