# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe SkillCertifier do
    subject { described_class.new(user, task) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:activity_one) { create(:activity, task:, active: true) }
    let(:activity_two) { create(:activity, task:, active: true) }

    before do
      activity_one
      activity_two
    end

    def skill_score
      Decidim::Gamification.status_for(user, :time_tracker_skills).score
    end

    context "when the user has completed all active activities" do
      before do
        create(:assignation, :completed, activity: activity_one, user:)
        create(:assignation, :completed, activity: activity_two, user:)
      end

      it "awards a skill certification" do
        expect { subject.refresh }.to change(SkillCertification, :count).by(1)
        expect(SkillCertification.find_by(user:, task:)).to be_present
      end

      it "increments the skills badge score" do
        expect { subject.refresh }.to change { skill_score }.by(1)
      end

      it "notifies the user" do
        # Allow every publish (awarding the badge also publishes a
        # gamification badge_earned event) and assert the certification one.
        allow(Decidim::EventsManager).to receive(:publish)

        subject.refresh

        expect(Decidim::EventsManager)
          .to have_received(:publish)
          .with(hash_including(event: "decidim.events.time_tracker.skill_certified_event", affected_users: [user]))
      end

      it "is idempotent" do
        subject.refresh
        expect { described_class.new(user, task).refresh }.not_to change(SkillCertification, :count)
      end
    end

    context "when the user has not completed all active activities" do
      before do
        create(:assignation, :completed, activity: activity_one, user:)
        create(:assignation, :accepted, activity: activity_two, user:)
      end

      it "does not award a certification" do
        expect { subject.refresh }.not_to change(SkillCertification, :count)
      end
    end

    context "when a skill is detached from the task after being certified" do
      let(:skill) { create(:skill, organization:, tasks: [task]) }
      let!(:certification) { create(:skill_certification, user:, task:, skill:) }

      before do
        Decidim::Gamification.set_score(user, :time_tracker_skills, 1)
        task.skills.destroy(skill)
      end

      it "revokes the certification the task can no longer grant" do
        expect { subject.refresh }.to change(SkillCertification, :count).by(-1)
      end

      it "decrements the skills badge score" do
        expect { subject.refresh }.to change { skill_score }.by(-1)
      end
    end

    context "when a certification exists but the task is no longer complete" do
      let!(:certification) { create(:skill_certification, user:, task:) }

      before do
        Decidim::Gamification.set_score(user, :time_tracker_skills, 1)
        create(:assignation, :accepted, activity: activity_one, user:)
      end

      it "revokes the certification" do
        expect { subject.refresh }.to change(SkillCertification, :count).by(-1)
      end

      it "decrements the skills badge score" do
        expect { subject.refresh }.to change { skill_score }.by(-1)
      end
    end
  end
end
