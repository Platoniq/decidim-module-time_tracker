# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe UserReportController do
    routes { Decidim::TimeTracker::Engine.routes }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, organization:) }
    let(:participatory_space) { create(:participatory_process, organization:) }
    let(:component) { create(:time_tracker_component, participatory_space:) }
    let(:time_tracker) { create(:time_tracker, component:) }
    let!(:task) { create(:task, time_tracker:) }
    let!(:activity) { create(:activity, task:) }
    let!(:assignation) { create(:assignation, activity:, user:) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
      sign_in user
    end

    describe "GET #show" do
      it "renders the report" do
        get :show
        expect(response).to have_http_status(:ok)
        expect(controller.helpers.assignations.count).to eq(1)
        expect(subject).to render_template(:show)
      end
    end
  end
end
