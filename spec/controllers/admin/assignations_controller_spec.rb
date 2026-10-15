# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe AssignationsController do
    routes { Decidim::TimeTracker::AdminEngine.routes }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, :admin, organization:) }
    let(:participatory_space) { create(:participatory_process, organization:) }
    let(:component) { create(:time_tracker_component, participatory_space:) }
    let(:time_tracker) { create(:time_tracker, component:) }
    let!(:task) { create(:task, time_tracker:) }
    let!(:activity) { create(:activity, task:) }
    let!(:assignation) { create(:assignation, :pending, activity:) }

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
        get(:index, params:)
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
        get(:new, params:)
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:new)
      end
    end

    describe "POST #create" do
      let(:params) do
        {
          task_id: task.id,
          activity_id: activity.id,
          assignation: form
        }
      end

      context "when there is permission" do
        it "returns ok" do
          post(:create, params:)
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "creates the new assignation" do
          post(:create, params:)
          expect(Decidim::TimeTracker::Assignation.last.user.name).to eq(form[:name])
          expect(Decidim::TimeTracker::Assignation.last.status).to eq("accepted")
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
          id: assignation.id,
          assignation_status: status
        }
      end

      context "when there is permission" do
        it "returns ok" do
          post(:update, params:)
          expect(response).to have_http_status(:redirect)
        end

        it "updates the new assignation" do
          post(:update, params:)
          expect(Decidim::TimeTracker::Assignation.first.status).to eq(status)
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
          id: assignation.id
        }
      end

      context "when there is permission" do
        it "returns ok" do
          delete(:destroy, params:)
          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        it "removes the assignation" do
          delete(:destroy, params:)
          expect { assignation.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "returning to success_path" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          task_id: task.id,
          activity_id: activity.id,
          id: assignation.id,
          assignation_status: "accepted",
          success_path:
        }
      end

      context "when it is a path on this site" do
        let(:success_path) { "/admin/participatory_processes/#{participatory_space.slug}/components/#{component.id}/manage/" }

        it "goes back there" do
          patch(:update, params:)
          expect(response).to redirect_to(success_path)
        end
      end

      ["https://evil.example.org/", "//evil.example.org/", "/\\evil.example.org/", "javascript:alert(1)"].each do |unsafe|
        context "when it is #{unsafe}" do
          let(:success_path) { unsafe }

          it "ignores it and returns to the activity's assignations" do
            patch(:update, params:)
            expect(response.location).not_to include("evil.example.org")
            expect(response.location).to end_with("/tasks/#{task.id}/activities/#{activity.id}/assignations")
          end
        end
      end
    end

    describe "records of another component" do
      let(:other_space) { create(:participatory_process, organization:) }
      let(:other_time_tracker) { create(:time_tracker, component: create(:time_tracker_component, participatory_space: other_space)) }
      let(:other_task) { create(:task, time_tracker: other_time_tracker) }
      let(:other_activity) { create(:activity, task: other_task) }
      let!(:other_assignation) { create(:assignation, :pending, activity: other_activity) }

      it "cannot be reached by putting their ids in this component's URL" do
        expect do
          patch(:update, params: { task_id: other_task.id, activity_id: other_activity.id, id: other_assignation.id, assignation_status: "accepted" })
        end.to raise_error(ActiveRecord::RecordNotFound)

        expect(other_assignation.reload).to be_pending
      end

      it "cannot be reached through one of this component's tasks either" do
        expect do
          patch(:update, params: { task_id: task.id, activity_id: activity.id, id: other_assignation.id, assignation_status: "accepted" })
        end.to raise_error(ActiveRecord::RecordNotFound)

        expect(other_assignation.reload).to be_pending
      end
    end
  end
end
