# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Skill do
    subject { skill }

    let(:organization) { create(:organization) }
    let(:skill) { create(:skill, organization:) }

    it { is_expected.to be_valid }

    it "is associated with an organization" do
      expect(subject.organization).to eq(organization)
    end

    it "is invalid without a name" do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    context "when assigned to tasks" do
      let(:time_tracker) { create(:time_tracker) }
      let(:task) { create(:task, time_tracker:) }

      before { task.skills << skill }

      it "is associated with the task" do
        expect(subject.tasks).to eq([task])
        expect(task.reload.skills).to eq([skill])
      end

      it "removes the assignment when destroyed" do
        expect { subject.destroy! }.to change(TaskSkill, :count).by(-1)
        expect(task.reload.skills).to be_empty
      end
    end

    describe "#earned_by?" do
      let(:time_tracker) { create(:time_tracker) }
      let(:task) { create(:task, time_tracker:) }
      let(:user) { create(:user, :confirmed, organization:) }
      let!(:activity_one) { create(:activity, task:, active: true) }
      let!(:activity_two) { create(:activity, task:, active: true) }

      before { task.skills << skill }

      context "with the completed_activities mode" do
        it "requires all activities by default" do
          create(:assignation, :completed, activity: activity_one, user:)
          expect(skill.earned_by?(user, task)).to be(false)

          create(:assignation, :completed, activity: activity_two, user:)
          expect(skill.earned_by?(user, task)).to be(true)
        end

        context "when a number of activities is set" do
          let(:skill) { create(:skill, organization:, required_activities_count: 1) }

          it "is earned after completing that many activities" do
            create(:assignation, :completed, activity: activity_one, user:)
            expect(skill.earned_by?(user, task)).to be(true)
          end
        end
      end

      context "with the time_spent mode" do
        let(:skill) { create(:skill, :time_based, organization:) }
        let(:assignation) { create(:assignation, :accepted, activity: activity_one, user:) }

        it "is earned once enough time is tracked on the task" do
          create(:time_event, assignation:, activity: activity_one, user:, start: 2.hours.ago.to_i, stop: Time.current.to_i, total_seconds: 1800)
          expect(skill.earned_by?(user, task)).to be(false)

          create(:time_event, assignation:, activity: activity_one, user:, start: 1.hour.ago.to_i, stop: Time.current.to_i, total_seconds: 1800)
          expect(skill.earned_by?(user, task)).to be(true)
        end
      end
    end
  end
end
