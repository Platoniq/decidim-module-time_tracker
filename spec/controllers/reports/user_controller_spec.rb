# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Reports
  describe UserController, type: :controller do
    routes { Decidim::TimeTracker::ReportsEngine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create :time_tracker_component, participatory_space: participatory_space }
    let(:time_tracker) { create :time_tracker, component: component }
    let!(:activity) { create :activity, task: task }
    let!(:task) { create :task, time_tracker: time_tracker }
    let!(:assignee) { create :assignee, activity: activity, user: user }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
      sign_in user
    end

    describe "GET #index" do
      it "renders the index listing" do
        get :index
        expect(response).to have_http_status(:ok)
        expect(controller.helpers.assignations.count).to eq(1)
        expect(subject).to render_template(:index)
      end
    end
  end
end
