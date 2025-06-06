# frozen_string_literal: true

require "spec_helper"
require "decidim/forms/test/factories"

module Decidim::TimeTracker
  describe ActivityQuestionnaireController do
    routes { Decidim::TimeTracker::Engine.routes }

    include_context "with a time_tracker"

    let(:user) { create(:user, :confirmed, organization:) }

    let!(:questionnaire) { time_tracker.questionnaire }
    let(:task) { create(:task, time_tracker:) }
    let!(:activity) { create(:activity, task:) }

    let(:form) do
      {
        name: Decidim::Faker::Localized.word
      }
    end

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
      time_tracker.reload
      sign_in user
    end

    shared_examples "renders the form readonly" do |can_answer|
      it "do not allow answers" do
        get(:show, params:)

        expect(response).to have_http_status(:ok)
        expect(controller.helpers.questionnaire_for).to eq(time_tracker)
        expect(controller.helpers.allow_answers?).to be(false)
        expect(controller.helpers.visitor_can_answer?).to eq(can_answer)
        expect(controller.helpers.visitor_already_answered?).not_to be(true)
        expect(subject).to render_template(:show)
      end
    end

    shared_examples "renders the form" do
      it "allows answers" do
        get(:show, params:)

        expect(response).to have_http_status(:ok)
        expect(controller.helpers.questionnaire_for).to eq(time_tracker)
        expect(controller.helpers.allow_answers?).to be(true)
        expect(controller.helpers.visitor_can_answer?).to be(true)
        expect(controller.helpers.visitor_already_answered?).to be(false)
        expect(subject).to render_template(:show)
      end
    end

    describe "GET #show" do
      let(:params) do
        {
          task_id: activity.task.id,
          activity_id: activity.id,
          id: questionnaire.id
        }
      end

      context "when user is not logged" do
        it_behaves_like "renders the form readonly", false
      end

      context "when user is logged" do
        before do
          sign_in user
        end

        context "and user is not an assignation" do
          it_behaves_like "renders the form readonly", false
        end

        context "and user is an assignation" do
          let!(:assignation) { create(:assignation, activity:, user:) }

          context "and questionnaire has no questions" do
            it_behaves_like "renders the form readonly", true
          end

          context "and questionnaire have questions" do
            let!(:question) { create(:questionnaire_question, question_type: :short_answer, body: Decidim::Faker::Localized.word, questionnaire:) }

            it_behaves_like "renders the form"
          end
        end
      end
    end

    describe "POST #answer" do
      let!(:question) { create(:questionnaire_question, question_type: :short_answer, body: Decidim::Faker::Localized.word, questionnaire:) }
      let(:tos_agreement) { "0" }
      let(:form) do
        {
          tos_agreement:,
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
          task_id: task.id,
          activity_id: activity.id,
          id: questionnaire.id,
          questionnaire: form
        }
      end

      before do
        sign_in user
      end

      context "and questionnaire is not valid" do
        it "do not update the form" do
          post(:answer, params:)

          expect(flash[:alert]).to be_present
          expect(questionnaire).not_to be_answered_by(user)
          expect(response).to render_template(:show)
        end
      end

      context "and questionnaire is valid" do
        let(:tos_agreement) { "1" }

        it "updates the form" do
          post(:answer, params:)

          expect(flash[:notice]).to be_present
          expect(questionnaire).to be_answered_by(user)
          expect(response).to have_http_status(:redirect)
        end
      end
    end
  end
end
