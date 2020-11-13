# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe MilestonesController, type: :controller do
    routes { Decidim::TimeTracker::Engine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { milestone.activity.task.component }
    let!(:assigne) { create :assignee, user: user, activity: milestone.activity }
    let(:milestone) { create :milestone, user: user }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
    end

    describe "post #create" do
      let(:params) do
        {
          milestone: {
            activity_id: activity_id,
            title: title,
            description: description,
            attachment: {
              title: ""
            }
          }
        }
      end
      let(:activity_id) { milestone.activity.id }
      let(:title) { "a new milestone" }
      let(:description) { "description" }

      context "when user is signed in" do
        before do
          sign_in user
        end

        it "creates a new milestone" do
          post :create, params: params
          expect(flash[:notice]).not_to be_blank
          expect(response).to have_http_status(:redirect)
        end

        context "when there's an error in the form" do
          let(:title) { "" }

          it "does not create a new milestone" do
            post :create, params: params
            expect(flash[:alert]).not_to be_blank
            expect(response).to have_http_status(:redirect)
          end
        end

        it "renders index" do
          get :index, params: { user_id: user.id }
          expect(response).to have_http_status(:ok)
          expect(subject).to render_template(:index)
        end
      end

      context "when user is not logged in" do
        it "redirects" do
          post :create, params: params
          expect(response).to redirect_to("/")
        end
      end
    end
  end
end
