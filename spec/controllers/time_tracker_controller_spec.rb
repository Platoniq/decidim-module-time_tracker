# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeTrackerController do
    include_context "with a time_tracker"

    let(:user) { create(:user, :confirmed, organization:) }

    let!(:milestone) { create(:milestone, activity:, user: assignations.first.user) }
    let!(:activity) { create(:activity, task:) }
    let!(:task) { create(:task, time_tracker:) }
    let!(:assignations) { create_list(:assignation, 3, :accepted, activity:) }

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
        expect(controller.helpers.tasks.count).to eq(1)
        expect(controller.helpers.task_list.milestones_for(activity)).to include(milestone)
        expect(subject).to render_template(:index)
      end
    end
  end
end
