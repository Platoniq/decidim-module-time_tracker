# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe VerifyCompletion do
    subject { described_class.new(completion, admin) }

    let(:organization) { create(:organization) }
    let(:admin) { create(:user, :admin, :confirmed, organization:) }
    let(:assignee) { create(:user, :confirmed, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:, active: true) }
    let(:assignation) { create(:assignation, :accepted, activity:, user: assignee) }
    let(:completion) { create(:activity_completion, assignation:) }

    def activities_score
      Decidim::Gamification.status_for(assignee, :time_tracker_activities).score
    end

    it "verifies the completion" do
      expect { subject.call }.to broadcast(:ok)
      expect(completion.reload).to be_verified
      expect(completion.verified_by).to eq(admin)
    end

    it "syncs the assignation completed_at" do
      subject.call
      expect(assignation.reload.completed_at).to be_present
    end

    it "increments the activities badge score" do
      expect { subject.call }.to change { activities_score }.by(1)
    end

    it "certifies the task skill once every activity is verified" do
      expect { subject.call }.to change(Decidim::TimeTracker::SkillCertification, :count).by(1)
    end

    context "when the completion is already verified" do
      let(:completion) { create(:activity_completion, :verified, assignation:) }

      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the task's skill requires several completions" do
      let!(:skill) { create(:skill, organization:, required_completions_per_activity: 2, tasks: [task]) }

      it "does not certify with a single verified completion" do
        expect { subject.call }.not_to change(Decidim::TimeTracker::SkillCertification, :count)
      end

      it "certifies once the second completion is verified" do
        subject.call

        second = create(:activity_completion, assignation:)
        expect { described_class.new(second, admin).call }.to change(Decidim::TimeTracker::SkillCertification, :count).by(1)
        expect(Decidim::TimeTracker::SkillCertification.last.skill).to eq(skill)
      end
    end
  end

  describe DismissCompletion do
    subject { described_class.new(completion, admin) }

    let(:organization) { create(:organization) }
    let(:admin) { create(:user, :admin, :confirmed, organization:) }
    let(:assignation) { create(:assignation, :accepted) }
    let!(:completion) { create(:activity_completion, assignation:) }

    it "destroys the pending completion" do
      expect { subject.call }.to change(Decidim::TimeTracker::ActivityCompletion, :count).by(-1)
    end

    context "when the completion is verified" do
      let!(:completion) { create(:activity_completion, :verified, assignation:) }

      it "broadcasts invalid and keeps the record" do
        expect { subject.call }.to broadcast(:invalid)
        expect(completion.reload).to be_persisted
      end
    end
  end
end
