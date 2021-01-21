# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker", type: :system do
  include_context "with a full time_tracker"

  let(:user) { create :user, :admin, organization: organization }

  before do
    switch_to_host(user.organization.host)
    login_as user, scope: :user
    visit_time_tracker_admin
  end

  it "shows activity counter next to component name in list" do
    expect(page).to have_link "Time Tracker #{time_tracker.activities.active.count}", href: time_tracker_admin_path
  end

  def visit_time_tracker_admin
    visit time_tracker_admin_path
  end

  def time_tracker_admin_path
    Decidim::EngineRouter.admin_proxy(component).root_path
  end
end
