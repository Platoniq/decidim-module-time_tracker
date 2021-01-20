# frozen_string_literal: true

require "spec_helper"
require "decidim/forms/test/factories"

module Decidim::TimeTracker
  describe AssigneeQuestionnaireController, type: :controller do
    routes { Decidim::TimeTracker::Engine.routes }

    include_context "with a time_tracker"

    let!(:assignee_data) { create :assignee_data, time_tracker: time_tracker }
    let!(:activity_questionnaire) { time_tracker.questionnaire }
    let!(:questionnaire) { assignee_data.questionnaire }
    let!(:assignee) { create :assignee, user: user }
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
          let!(:question) { create :questionnaire_question, question_type: :short_answer, body: Decidim::Faker::Localized.word, questionnaire: questionnaire }

          it_behaves_like "renders the form"
        end
      end
    end

    describe "POST #answer" do
      let!(:question) { create :questionnaire_question, question_type: :short_answer, body: Decidim::Faker::Localized.word, questionnaire: questionnaire }
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
          expect(Decidim::TimeTracker::TosAcceptance.count).to be_zero
        end
      end

      context "and questionnaire is valid" do
        let(:tos_agreement) { "1" }

        it "updates the form" do
          post :answer, params: params

          expect(flash[:notice]).to be_present
          expect(questionnaire).to be_answered_by(user)
          expect(response).to have_http_status(:redirect)
          expect(Decidim::TimeTracker::TosAcceptance.last.assignee).to eq(assignee)
        end
      end
    end
  end
end
