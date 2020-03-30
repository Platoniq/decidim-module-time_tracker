# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    module Admin
      describe ActivitiesController, type: :controller do
        routes { Decidim::TimeTracker::AdminEngine.routes }

        let(:organization) { create :organization }
        let(:user) { create(:user, :confirmed, :admin, organization: organization) }
        let(:participatory_space) { create(:participatory_process, organization: organization) }
        let(:component) { create :time_tracker_component, participatory_space: participatory_space }
        let!(:time_tracker) { create :time_tracker, component: component }
        let!(:task) { create :task, time_tracker: time_tracker }

        let(:form) do
          {
            description: Decidim::Faker::Localized.sentence(3),
            active: false,
            start_date: 1.day.ago,
            end_date: 1.month.from_now,
            max_minutes_per_day: 60,
            requests_start_at: Time.zone.today,
            task: task
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
              participatory_process_slug: component.participatory_space.slug,
              task_id: task.id
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
              participatory_process_slug: component.participatory_space.slug,
              task_id: task.id
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
              activity: form
            }
          end

          context "when there is permission" do
            it "returns ok" do
              post :create, params: params
              expect(flash[:notice]).not_to be_empty
              expect(response).to have_http_status(:found)
            end

            it "creates the new activity" do
              post :create, params: params
              expect(Decidim::TimeTracker::Activity.first.description).to eq(form[:description])
            end
          end
        end

        describe "PATCH #update" do
          let!(:activity) { create :activity, task: task }
          let(:form) do
            {
              description: Decidim::Faker::Localized.sentence(3),
              active: false,
              start_date: 1.day.ago,
              end_date: 1.month.from_now,
              max_minutes_per_day: 60,
              requests_start_at: Time.zone.today,
              task: task
            }
          end

          let(:params) do
            {
              task_id: task.id,
              id: activity.id,
              activity: form
            }
          end

          context "when there is permission" do
            it "returns ok" do
              patch :update, params: params
              expect(flash[:notice]).not_to be_empty
              expect(response).to have_http_status(:found)
            end

            it "updates the activity" do
              patch :update, params: params
              expect(Decidim::TimeTracker::Activity.first.description).to eq(form[:description])
            end
          end
        end

        describe "DELETE #destroy" do
          let!(:activity) { create :activity, task: task }

          let(:params) do
            {
              component_id: time_tracker.component.id,
              participatory_process_slug: time_tracker.component.participatory_space.slug,
              task_id: task.id,
              id: activity.id
            }
          end

          context "when there is permission" do
            it "returns ok" do
              delete :destroy, params: params
              expect(flash[:notice]).not_to be_empty
              expect(response).to have_http_status(:found)
            end

            it "updates the new task" do
              delete :destroy, params: params
              expect { activity.reload }.to raise_error(ActiveRecord::RecordNotFound)
            end
          end
        end
      end
    end
  end
end
