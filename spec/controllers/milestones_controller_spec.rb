# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe MilestonesController do
    routes { Decidim::TimeTracker::Engine.routes }

    include_context "with a time_tracker"

    let(:user) { create(:user, :confirmed, organization:) }

    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:) }
    let(:milestone) { create(:milestone, user:, activity:) }  # Add activity: here
    let!(:assigne) { create(:assignation, user:, activity: milestone.activity) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
    end

    describe "post #create" do
      let(:params) do
        {
          milestone: {
            activity_id:,
            title:,
            description:,
            attachment: {
              title: ""
            }
          }
        }
      end
      let(:activity_id) { activity.id }  # Change from milestone.activity.id to activity.id
      let(:title) { "a new milestone" }
      let(:description) { "description" }

      context "when user is signed in" do
        before do
          sign_in user
        end

        it "creates a new milestone" do
          post(:create, params:)
          expect(flash[:notice]).not_to be_blank
          expect(response).to have_http_status(:redirect)
        end

        context "when there's an error in the form" do
          let(:title) { "" }

          it "does not create a new milestone" do
            post(:create, params:)
            expect(flash[:alert]).not_to be_blank
            expect(response).to have_http_status(:redirect)
          end
        end
      end

      context "when user is not signed in" do
        it "redirects" do
          post(:create, params:)
          expect(response).to redirect_to("/users/sign_in")
        end
      end
    end

    describe "get #index" do
      context "when user is signed in" do
        before do
          sign_in user
        end

        context "when the nickname param is provided" do
          it "renders index" do
            get :index, params: { nickname: user.nickname }
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)
          end
        end

        context "when the nickname param is missing" do
          it "redirects" do
            get :index
            expect(response).to redirect_to(root_path)
          end
        end
      end

      context "when user is not signed in" do
        it "redirects" do
          get :index, params: { nickname: user.nickname }
          expect(response).to redirect_to("/users/sign_in")
        end
      end
    end
  end
end
