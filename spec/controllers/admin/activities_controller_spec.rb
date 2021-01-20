# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe ActivitiesController, type: :controller do
    routes { Decidim::TimeTracker::AdminEngine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create :time_tracker_component, participatory_space: participatory_space }
    let(:time_tracker) { create :time_tracker, component: component }
    let!(:task) { create :task, time_tracker: time_tracker }
    let!(:activity) { create :activity, task: task }

    let(:activity_params) do
      {
        description: Decidim::Faker::Localized.sentence(3),
        active: false,
        start_date: 1.day.from_now.strftime("%d/%m/%Y %H:%M"),
        end_date: 1.month.from_now.strftime("%d/%m/%Y %H:%M"),
        max_minutes_per_day: 60,
        requests_start_at: Time.zone.now.strftime("%d/%m/%Y %H:%M"),
        task_id: task.id
      }
    end

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_process"] = participatory_space
      request.env["decidim.current_component"] = component
      sign_in user
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

    describe "GET #edit" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: component.participatory_space.slug,
          task_id: task.id,
          id: activity.id
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
          task_id: task.id,
          activity: activity_params
        }
      end

      context "when there is permission" do
        it "returns ok" do
          post :create, params: params
          expect(flash[:notice]).to be_present
          expect(response).to have_http_status(:found)
        end

        it "creates the new activity" do
          post :create, params: params
          expect(Decidim::TimeTracker::Activity.last.description).to eq(activity_params[:description])
        end
      end

      context "when params are invalid" do
        let!(:activity_params) do
          {
            description: {}
          }
        end

        it "returns invalid" do
          post :create, params: params
          expect(flash.now[:alert]).not_to be_blank
          expect(response).to have_http_status(:ok)
        end

        it "does not create the new activity" do
          post :create, params: params
          expect(Decidim::TimeTracker::Activity.count).to eq(1)
        end
      end
    end

    describe "PATCH #update" do
      let(:activity_params) do
        {
          description: Decidim::Faker::Localized.sentence(3),
          active: false,
          start_date: 1.month.ago.strftime("%d/%m/%Y %H:%M"),
          end_date: 1.month.from_now.strftime("%d/%m/%Y %H:%M"),
          max_minutes_per_day: 60,
          requests_start_at: 2.months.ago.strftime("%d/%m/%Y %H:%M"),
          task: task
        }
      end

      let(:params) do
        {
          task_id: task.id,
          id: activity.id,
          activity: activity_params
        }
      end

      context "when there is permission" do
        it "returns ok" do
          patch :update, params: params
          expect(flash[:notice]).to be_present
          expect(response).to have_http_status(:found)
        end

        it "updates the activity" do
          patch :update, params: params
          expect(Decidim::TimeTracker::Activity.first.description).to eq(activity_params[:description])
        end
      end

      context "when params are invalid" do
        let!(:activity_params) do
          {
            description: {}
          }
        end

        it "returns invalid" do
          post :update, params: params
          expect(flash.now[:alert]).not_to be_blank
          expect(response).to have_http_status(:ok)
        end

        it "does not create the new activity" do
          post :update, params: params
          expect(Decidim::TimeTracker::Activity.first.description).to eq(activity[:description])
        end
      end
    end

    describe "DELETE #destroy" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: component.participatory_space.slug,
          task_id: task.id,
          id: activity.id
        }
      end

      context "when there is permission" do
        it "returns ok" do
          delete :destroy, params: params
          expect(flash[:notice]).to be_present
          expect(response).to have_http_status(:found)
        end

        it "destroys the activity" do
          delete :destroy, params: params
          expect { activity.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
