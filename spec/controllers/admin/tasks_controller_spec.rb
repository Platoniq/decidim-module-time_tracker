# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe TasksController, type: :controller do
    routes { Decidim::TimeTracker::AdminEngine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create :time_tracker_component, participatory_space: participatory_space }
    let!(:task) { create :task, component: component }

    let(:form) do
      {
        name: Decidim::Faker::Localized.word
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
          participatory_process_slug: participatory_space.slug
        }
      end

      it "renders the index listing" do
        get :index, params: params
        expect(controller.helpers.tasks.count).to eq(1)
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:index)
      end
    end

    describe "GET #new" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug
        }
      end

      it "renders the empty form" do
        get :new, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:new)
      end
    end

    describe "GET #edit" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          id: task.id
        }
      end

      it "renders the empty form" do
        get :edit, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:edit)
      end
    end

    describe "POST #create" do
      let(:params) do
        {
          task: form
        }
      end

      context "when there is permission" do
        it "returns ok" do
          post :create, params: params
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "creates the new task" do
          post :create, params: params
          expect(Decidim::TimeTracker::Task.last.name).to eq(form[:name])
        end
      end
    end

    describe "PATCH #update" do
      let!(:task) { create :task, component: component }
      let(:form) do
        {
          name: Decidim::Faker::Localized.word
        }
      end

      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          id: task.id,
          task: form
        }
      end

      context "when there is permission" do
        it "returns ok" do
          patch :update, params: params
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "updates the new task" do
          patch :update, params: params
          expect(Decidim::TimeTracker::Task.last.name).to eq(form[:name])
        end
      end
    end

    describe "DELETE #destroy" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          id: task.id
        }
      end

      context "when there is permission" do
        it "returns ok" do
          delete :destroy, params: params
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "destroy the task" do
          delete :destroy, params: params
          expect { task.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
