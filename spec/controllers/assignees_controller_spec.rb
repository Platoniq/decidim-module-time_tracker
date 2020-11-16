# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe AssigneesController, type: :controller do
    routes { Decidim::TimeTracker::Engine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create :time_tracker_component, participatory_space: participatory_space }
    let(:time_tracker) { create :time_tracker, component: component }
    let(:task) { create :task, time_tracker: time_tracker }
    let(:activity) { create :activity, task: task }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
    end

    describe "post #create" do
      let(:params) do
        {
          activity_id: activity.id
        }
      end

      context "when user is signed in" do
        before do
          sign_in user
        end

        it "creates a new assignee" do
          post :create, params: params
          expect(response).to have_http_status(:ok)
        end

        context "when activity is not active" do
          let(:activity) { create :activity, task: task, active: false }

          it "do not create a new assignee" do
            post :create, params: params
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context "when user is not logged in" do
        it "redirects" do
          post :create, params: params
          expect(response).to redirect_to("/")
        end
      end
    end

    describe "get #show" do
      let(:assignee) { create(:assignee, activity: activity, user: user) }
      let(:params) do
        {
          id: assignee.id
        }
      end

      it "returns the show view" do
        get :show, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:show)
      end
    end
  end
end
