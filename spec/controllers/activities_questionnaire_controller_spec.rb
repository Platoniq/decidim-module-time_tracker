# frozen_string_literal: true

require "spec_helper"
require "decidim/forms/test/factories"

module Decidim::TimeTracker
  describe ActivitiesQuestionnaireController, type: :controller do
    routes { Decidim::TimeTracker::Engine.routes }

    let(:organization) { create :organization }
    let(:user) { create(:user, :confirmed, :admin, organization: organization) }
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { activity.task.component }
    let(:questionnaire) { create :questionnaire }
    let(:task) { create :task, questionnaire: questionnaire }
    let!(:activity) { create :activity, task: task }

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

    shared_examples "renders the form readonly" do |can_answer|
      it "do not allow answers" do
        get :show, params: params

        expect(response).to have_http_status(:ok)
        expect(controller.helpers.questionnaire_for).to eq(activity.task)
        expect(controller.helpers.allow_answers?).to eq(false)
        expect(controller.helpers.visitor_can_answer?).to eq(can_answer)
        expect(controller.helpers.visitor_already_answered?).not_to eq(true)
        expect(subject).to render_template(:show)
      end
    end

    shared_examples "renders the form" do
      it "allows answers" do
        get :show, params: params

        expect(response).to have_http_status(:ok)
        expect(controller.helpers.questionnaire_for).to eq(activity.task)
        expect(controller.helpers.allow_answers?).to eq(true)
        expect(controller.helpers.visitor_can_answer?).to eq(true)
        expect(controller.helpers.visitor_already_answered?).to eq(false)
        expect(subject).to render_template(:show)
      end
    end

    describe "GET #show" do
      let(:params) do
        {
          task_id: activity.task.id,
          activity_id: activity.id,
          id: activity.questionnaire.id
        }
      end

      context "when user is not logged" do
        it_behaves_like "renders the form readonly", false
      end

      context "when user is logged" do
        before do
          sign_in user
        end

        context "and user is not an assignee" do
          it_behaves_like "renders the form readonly", false
        end

        context "and user is an assignee" do
          let!(:assignee) { create :assignee, activity: activity, user: user }

          context "and questionnaire do not have questions" do
            it_behaves_like "renders the form readonly", true
          end

          context "and questionnaire have questions" do
            let(:questionnaire) { create :questionnaire, :with_questions }

            it_behaves_like "renders the form"
          end
        end
      end
    end
  end
end
