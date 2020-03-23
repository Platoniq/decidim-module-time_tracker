# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    module Admin
      describe TasksController, type: :controller do
        routes { Decidim::TimeTracker::AdminEngine.routes }

        let(:organization) { create :organization }
        let(:user) { create(:user, :confirmed, :admin, organization: organization) }
        let(:participatory_space) { create(:participatory_process, organization: organization) }
        let(:component) { create :time_tracker_component, participatory_space: participatory_space }
        let!(:time_tracker) { create :time_tracker, component: component }

        let(:form) do
          {
            name: Decidim::Faker::Localized.word
          }
        end

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_component"] = component
          sign_in user
        end

        describe "GET #index" do
          let(:params) do
            {
              component_id: component.id,
              participatory_process_slug: component.participatory_space.slug,
              id: time_tracker.id
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
              id: time_tracker.id
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
              time_tracker: {
                decidim_assemblies_component_id: time_tracker.component.id
              },
              component_id: component.id,
              participatory_process_slug: component.participatory_space.slug,
              id: time_tracker.id,
              task: form
            }
          end

          context "when there is permission" do
            it "returns ok" do
              post :create, params: form
              expect(flash[:notice]).not_to be_empty
              expect(response).to have_http_status(:found)
            end

            it "creates the new task" do
              post :create, params: form
              expect(Decidim::TimeTracker::Task.first.name).to eq(form[:name])
            end
          end
        end
      end
    end
  end
end
