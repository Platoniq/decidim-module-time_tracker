# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe AssigneesController, type: :controller do
      routes { Decidim::TimeTracker::Engine.routes }

      let(:organization) { create :organization }
      let(:user) { create(:user, :confirmed, :admin, organization: organization) }
      let(:participatory_space) { create(:participatory_process, organization: organization) }
      let(:component) { create :time_tracker_component, participatory_space: participatory_space }
      let(:task) { create :task, component: component }
      let(:activity) { create :activity, task: task }

      before do
        request.env["decidim.current_organization"] = organization
        request.env["decidim.current_participatory_space"] = participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "get #new" do
        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id
          }
        end

        it "creates a new assignee" do
          get :new, params: params
          expect(response).to redirect_to(EngineRouter.main_proxy(component).root_path)
        end
      end

      describe "get #show" do
        let(:assignee) { create(:assignee, activity: activity, user: user) }
        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id,
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
end
