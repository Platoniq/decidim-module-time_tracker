# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe Permissions do
    subject { described_class.new(user, permission_action, context).permissions.allowed? }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:context) do
      {
        current_organization: organization
      }
    end
    let(:permission_action) { Decidim::PermissionAction.new(**action) }

    context "when scope is not admin" do
      let(:action) do
        { scope: :foo, action: :read, subject: :template }
      end

      it_behaves_like "permission is not set"
    end

    context "when subject is not an assignation, an activity, a questionnaire, or a task" do
      let(:action) do
        { scope: :admin, action: :read, subject: :foo }
      end

      it_behaves_like "permission is not set"
    end

    context "when action is a random one" do
      let(:action) do
        { scope: :admin, action: :foo, subject: :activity }
      end

      it_behaves_like "permission is not set"
    end

    shared_examples_for "action is allowed" do |scope, action, subject|
      let(:action) do
        { scope:, action:, subject: }
      end

      it { is_expected.to be true }
    end

    context "when subject is a task" do
      context "when indexing" do
        it_behaves_like "action is allowed", :admin, :index, :tasks
      end

      context "when creating" do
        it_behaves_like "action is allowed", :admin, :create, :task
      end

      context "when updating" do
        it_behaves_like "action is allowed", :admin, :update, :task
      end

      context "when destroying" do
        it_behaves_like "action is allowed", :admin, :destroy, :task
      end
    end

    context "when subject is an activity" do
      context "when indexing" do
        it_behaves_like "action is allowed", :admin, :index, :activities
      end

      context "when creating" do
        it_behaves_like "action is allowed", :admin, :create, :activity
      end

      context "when updating" do
        it_behaves_like "action is allowed", :admin, :update, :activity
      end

      context "when destroying" do
        it_behaves_like "action is allowed", :admin, :destroy, :activity
      end
    end

    context "when subject is a questionnaire" do
      context "when previewing" do
        it_behaves_like "action is allowed", :admin, :preview, :questionnaire
      end

      context "when updating" do
        it_behaves_like "action is allowed", :admin, :update, :questionnaire
      end

      context "when exporting answers" do
        it_behaves_like "action is allowed", :admin, :export_answers, :questionnaire
      end
    end

    context "when subject is questionnaire_answers" do
      context "when showing" do
        it_behaves_like "action is allowed", :admin, :show, :questionnaire_answers
      end

      context "when indexing" do
        it_behaves_like "action is allowed", :admin, :index, :questionnaire_answers
      end

      context "when exporting responses" do
        it_behaves_like "action is allowed", :admin, :export_response, :questionnaire_answers
      end
    end

    context "when subject is an assignation" do
      context "when indexing" do
        it_behaves_like "action is allowed", :admin, :index, :assignations
      end

      context "when creating" do
        it_behaves_like "action is allowed", :admin, :create, :assignation
      end

      context "when destroying" do
        it_behaves_like "action is allowed", :admin, :destroy, :assignation
      end

      context "when updating" do
        let(:assignation) { create(:assignation) }
        let(:context) do
          { assignation: }
        end

        context "when the assignation has no time events" do
          it_behaves_like "action is allowed", :admin, :update, :assignation
        end

        context "when the assignation has time events" do
          let!(:time_event) { create(:time_event, assignation:, total_seconds: 30) }
          let(:action) do
            { scope: :admin, action: :update, subject: :assignation }
          end

          it_behaves_like "permission is not set"
        end
      end
    end
  end
end
