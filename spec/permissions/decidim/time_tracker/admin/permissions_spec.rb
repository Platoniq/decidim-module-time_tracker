# frozen_string_literal: true

require "spec_helper"

describe Decidim::TimeTracker::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:organization) { create :organization }
  let(:user) { create :user, organization: organization }
  let(:context) do
    {
      current_organization: organization
    }
  end
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  context "when scope is not admin" do
    let(:action) do
      { scope: :foo, action: :read, subject: :template }
    end

    it_behaves_like "permission is not set"
  end

  context "when subject is not an assignee, an activity, or a task" do
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
      { scope: scope, action: action, subject: subject }
    end

    it { is_expected.to eq true }
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

  context "when subject is an assignee" do
    context "when indexing" do
      it_behaves_like "action is allowed", :admin, :index, :assignees
    end

    context "when creating" do
      it_behaves_like "action is allowed", :admin, :create, :assignee
    end

    context "when destroying" do
      it_behaves_like "action is allowed", :admin, :destroy, :assignee
    end

    context "when updating" do
      let(:assignee) { create(:assignee) }
      let(:context) do
        { assignee: assignee }
      end

      context "when the assignee has no time events" do
        it_behaves_like "action is allowed", :admin, :update, :assignee
      end

      context "when the assignee has time events" do
        let!(:time_event) { create(:time_event, assignee: assignee, total_seconds: 30) }
        let(:action) do
          { scope: :admin, action: :update, subject: :assignee }
        end

        it_behaves_like "permission is not set"
      end
    end
  end
end
