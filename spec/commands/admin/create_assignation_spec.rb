# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateAssignation do
    subject { described_class.new(form, activity) }

    let(:form) do
      double(
        # AssignationForm,
        name: Faker::Name.name,
        email: "user@example.org",
        existing_user:,
        invalid?: invalid,
        current_user: user
      )
    end

    let(:activity) { create(:activity, task:) }
    let(:task) { create(:task) }
    let(:user) { create(:user, :admin, :confirmed, organization:) }
    let(:organization) { create(:organization) }
    let(:invalid) { false }
    let(:existing_user) { false }

    context "when the form is not valid" do
      let(:invalid) { true }

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the form is valid" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new assignation for the activity" do
        expect { subject.call }.to change(Decidim::TimeTracker::Assignation, :count).by(1)
      end

      it "traces the action", :versioning do
        expect(Decidim.traceability)
          .to receive(:create!)
          .with(Decidim::TimeTracker::Assignation, user, hash_including(:user, :activity, :status, :invited_at, :invited_by_user))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end

    context "when the form has an existing user" do
      let(:existing_user) { true }
      let(:user) { create(:user, organization:) }

      let(:form) do
        double(
          # AssignationForm,
          name: user.name,
          email: user.email,
          existing_user:,
          invalid?: false,
          current_user: user,
          user:
        )
      end

      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new assignation for the activity" do
        expect { subject.call }.to change(Decidim::TimeTracker::Assignation, :count).by(1)
      end

      it "traces the action", :versioning do
        expect(Decidim.traceability)
          .to receive(:create!)
          .with(Decidim::TimeTracker::Assignation, user, hash_including(:user, :activity, :status, :invited_at, :invited_by_user))
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        # action_log = Decidim::ActionLog.last
        # expect(action_log.version).to be_present
      end
    end
  end
end
