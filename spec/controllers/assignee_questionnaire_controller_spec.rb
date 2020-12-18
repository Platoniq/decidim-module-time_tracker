# frozen_string_literal: true

require "spec_helper"
require "decidim/forms/test/factories"

module Decidim::TimeTracker
  describe AssigneeQuestionnaireController, type: :controller do
    routes { Decidim::TimeTracker::Engine.routes }

    let!(:user) { create(:user, :confirmed, organization: organization) }
    let(:organization) { create(:organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create(:time_tracker_component, participatory_space: participatory_space) }
    let(:time_tracker) { create(:time_tracker, component: component, questionnaire: activity_questionnaire) }
    let!(:activity_questionnaire) { create :questionnaire }
    let!(:assignee_data) { create :assignee_data, time_tracker: time_tracker, questionnaire: questionnaire }
    let!(:questionnaire) { create :questionnaire }
    let(:task) { create :task, time_tracker: time_tracker }

    let(:form) do
      {
        name: Decidim::Faker::Localized.word
      }
    end

    let(:session_token) { "fake-hash-for-#{user.id}" }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
      time_tracker.reload
    end

    shared_examples "renders the form readonly" do |can_answer|
      it "does not allow answers" do
        get :show

        expect(response).to have_http_status(:ok)
        expect(controller.helpers.questionnaire_for).to eq(assignee_data)
        expect(controller.helpers.allow_answers?).not_to eq(true)
        expect(controller.helpers.visitor_can_answer?).to eq(can_answer)
        expect(controller.helpers.visitor_already_answered?).not_to eq(true)
        expect(subject).to render_template(:show)
      end
    end

    shared_examples "renders the form" do
      it "allows answers" do
        get :show

        expect(response).to have_http_status(:ok)
        expect(controller.helpers.questionnaire_for).to eq(assignee_data)
        expect(controller.helpers.allow_answers?).to eq(true)
        expect(controller.helpers.visitor_can_answer?).not_to eq(false) # visitor_can_answer? returns the instance of current_user when present, not 'true'
        expect(controller.helpers.visitor_already_answered?).not_to eq(true)
        expect(subject).to render_template(:show)
      end
    end

    describe "GET #show" do
      context "when user is not logged" do
        it_behaves_like "renders the form readonly", false
      end

      context "when user is logged" do
        before do
          sign_in user
        end

        context "and questionnaire has no questions" do
          it_behaves_like "renders the form"
        end

        context "and questionnaire have questions" do
          let!(:question) { create :questionnaire_question, question_type: :short_answer, body: "name", questionnaire: questionnaire }

          it_behaves_like "renders the form"
        end
      end
    end

    describe "POST #answer" do
      let!(:question) { create :questionnaire_question, question_type: :short_answer, body: "name", questionnaire: questionnaire }
      let(:tos_agreement) { "0" }
      let(:form) do
        {
          tos_agreement: tos_agreement,
          responses: {
            "0" => {
              body: "Tom",
              question_id: question.id
            }
          }
        }
      end
      let(:params) do
        {
          id: questionnaire.id,
          questionnaire: form
        }
      end

      before do
        sign_in user
      end

      context "and questionnaire is not valid" do
        it "do not update the form" do
          post :answer, params: params

          expect(flash[:alert]).to be_present
          expect(questionnaire).not_to be_answered_by(user)
          expect(response).to render_template(:show)
        end
      end

      context "and questionnaire is valid" do
        let(:tos_agreement) { "1" }

        it "updates the form" do
          post :answer, params: params

          expect(flash[:notice]).to be_present
          expect(questionnaire).to be_answered_by(user)
          expect(response).to have_http_status(:redirect)
        end
      end
    end
  end
end
