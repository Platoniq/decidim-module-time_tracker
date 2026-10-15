# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CompleteAssignation do
    subject { described_class.new(assignation, user, complete:) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, :admin, organization:) }
    let(:assignee) { create(:user, :confirmed, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:, active: true) }
    let(:assignation) { create(:assignation, activity:, user: assignee, status:) }
    let(:status) { :accepted }
    let(:complete) { true }

    def activities_score
      Decidim::Gamification.status_for(assignee, :time_tracker_activities).score
    end

    context "when completing an accepted assignation" do
      it "sets completed_at" do
        subject.call
        expect(assignation.reload.completed_at).to be_present
      end

      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "increments the activities badge score" do
        expect { subject.call }.to change { activities_score }.by(1)
      end

      it "refreshes the skill certification" do
        expect_any_instance_of(Decidim::TimeTracker::SkillCertifier).to receive(:refresh) # rubocop:disable RSpec/AnyInstance
        subject.call
      end

      context "when it is the only active activity of the task" do
        it "certifies the skill" do
          expect { subject.call }.to change(Decidim::TimeTracker::SkillCertification, :count).by(1)
        end
      end
    end

    context "when the assignation is not accepted" do
      let(:status) { :pending }

      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end

      it "does not set completed_at" do
        subject.call
        expect(assignation.reload.completed_at).to be_nil
      end
    end

    context "when uncompleting a completed assignation" do
      let(:complete) { false }
      let(:assignation) { create(:assignation, :completed, activity:, user: assignee) }

      before do
        Decidim::Gamification.set_score(assignee, :time_tracker_activities, 1)
      end

      it "clears completed_at" do
        subject.call
        expect(assignation.reload.completed_at).to be_nil
      end

      it "decrements the activities badge score" do
        expect { subject.call }.to change { activities_score }.by(-1)
      end
    end

    context "when completing an already completed assignation" do
      let(:assignation) { create(:assignation, :completed, activity:, user: assignee) }

      it "adds another verified completion" do
        expect { subject.call }.to broadcast(:ok)
        expect(assignation.reload.verified_completions_count).to eq(2)
      end
    end

    context "when reverting an assignation without verified completions" do
      let(:complete) { false }
      let(:assignation) { create(:assignation, :accepted, activity:, user: assignee) }

      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when a pending completion exists" do
      let(:assignation) { create(:assignation, :accepted, activity:, user: assignee) }
      let!(:pending_completion) { create(:activity_completion, assignation:) }

      it "verifies it instead of creating a new record" do
        expect { subject.call }.not_to change(Decidim::TimeTracker::ActivityCompletion, :count)
        expect(pending_completion.reload).to be_verified
        expect(assignation.reload.completed_at).to be_present
      end
    end
  end
end
