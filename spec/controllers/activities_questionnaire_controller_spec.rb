# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe ActivitiesQuestionnaireController, type: :controller do
    routes { Decidim::TimeTracker::Engine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { activity.task.component }
    let(:assignee) { create :assignee, activity: activity, user: user }
    let!(:activity) { create :activity }

    let(:form) do
      {
        name: Decidim::Faker::Localized.word
      }
    end

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
      sign_in user
    end

    describe "GET #show" do
      let(:params) do
        {
          task_id: activity.task.id,
          activity_id: activity.id,
          id: activity.questionnaire.id
        }
      end

      it "renders the form" do
        get :show, params: params
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:show)
      end
    end
  end
end
