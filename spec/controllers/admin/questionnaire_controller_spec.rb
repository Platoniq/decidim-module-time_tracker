# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe QuestionnaireController, type: :controller do
    routes { Decidim::TimeTracker::AdminEngine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create :time_tracker_component, participatory_space: participatory_space }
    let(:time_tracker) { create :time_tracker, component: component }
    let!(:task) { create :task, time_tracker: time_tracker }

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

    describe "GET #edit" do
      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug
        }
      end

      it "renders the edit form" do
        get :edit, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:edit)
      end
    end

    describe "PATCH #update" do
      let(:form) do
        {
          title: Decidim::Faker::Localized.sentence(3),
          tos: Decidim::Faker::Localized.sentence(3)
        }
      end

      let(:params) do
        {
          component_id: component.id,
          participatory_process_slug: participatory_space.slug,
          questionnaire: form
        }
      end

      it "returns ok" do
        patch :update, params: params
        expect(flash[:notice]).not_to be_empty
        expect(response).to have_http_status(:redirect)
      end

      it "updates the questionnaire" do
        patch :update, params: params
        expect(Decidim::TimeTracker::Task.first.questionnaire.title).to eq(form[:title])
      end
    end
  end
end
