# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe AssignationsController do
    routes { Decidim::TimeTracker::Engine.routes }

    include_context "with a time_tracker"

    let(:user) { create(:user, :confirmed, organization:) }

    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:) }

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

        it "creates a new assignation" do
          post(:create, params:)
          expect(response).to have_http_status(:ok)
        end

        context "when activity is not active" do
          let(:activity) { create(:activity, task:, active: false) }

          it "do not create a new assignation" do
            post(:create, params:)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context "when user is not logged in" do
        it "redirects" do
          post(:create, params:)
          expect(response).to redirect_to("/users/sign_in")
        end
      end
    end
  end
end
