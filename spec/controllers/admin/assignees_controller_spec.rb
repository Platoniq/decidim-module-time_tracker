# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe AssigneesController, type: :controller do
    routes { Decidim::TimeTracker::AdminEngine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create :time_tracker_component, participatory_space: participatory_space }
    let!(:task) { create :task, component: component }
    let!(:activity) { create :activity, task: task }
    let!(:assignee) { create :assignee, :pending, activity: activity }

    let(:form) do
      {
        name: ::Faker::Name.name,
        email: "user@example.org"
      }
    end

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_process"] = participatory_space
      request.env["decidim.current_component"] = component
      sign_in user
    end

    describe "GET #index" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          task_id: task.id,
          activity_id: activity.id
        }
      end

      it "renders the index listing" do
        get :index, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:index)
      end
    end

    describe "GET #new" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          task_id: task.id,
          activity_id: activity.id
        }
      end

      it "renders the empty form" do
        get :new, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:new)
      end
    end

    describe "POST #create" do
      let(:params) do
        {
          task_id: task.id,
          activity_id: activity.id,
          assignee: form
        }
      end

      context "when there is permission" do
        it "returns ok" do
          post :create, params: params
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "creates the new assignee" do
          post :create, params: params
          expect(Decidim::TimeTracker::Assignee.last.user.name).to eq(form[:name])
          expect(Decidim::TimeTracker::Assignee.last.status).to eq("accepted")
        end
      end
    end

    describe "PATCH #update" do
      let(:status) { "accepted" } 
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          task_id: task.id,
          activity_id: activity.id,
          id: assignee.id,
          assignee_status: status
        }
      end

      context "when there is permission" do
        it "returns ok" do
          post :update, params: params
          expect(response).to have_http_status(:redirect)
        end

        it "updates the new assignee" do
          post :update, params: params
          expect(Decidim::TimeTracker::Assignee.first.status).to eq(status)
        end
      end
    end

    describe "DELETE #destroy" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          task_id: task.id,
          activity_id: activity.id,
          id: assignee.id
        }
      end

      context "when there is permission" do
        it "returns ok" do
          delete :destroy, params: params
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "removes the assignee" do
          delete :destroy, params: params
          expect { assignee.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
