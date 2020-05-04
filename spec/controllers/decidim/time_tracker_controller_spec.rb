# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeTrackerController, type: :controller do
      routes { Decidim::TimeTracker::Engine.routes }

      let(:organization) { create :organization }
      let(:user) { create(:user, :confirmed, :admin, organization: organization) }
      let(:participatory_space) { create(:participatory_process, organization: organization) }
      let(:component) { create :time_tracker_component, participatory_space: participatory_space }
      let!(:task) { create :task, component: component }

      before do
        request.env["decidim.current_organization"] = organization
        request.env["decidim.current_participatory_process"] = participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "GET #index" do
        let(:params) do
          {
            participatory_process_slug: component.participatory_space.slug,
            component_id: component.id
          }
        end

        it "renders the index listing" do
          get :index, params: params
          expect(response).to have_http_status(:ok)
          expect(subject).to render_template(:index)
        end
      end
    end
  end
end
