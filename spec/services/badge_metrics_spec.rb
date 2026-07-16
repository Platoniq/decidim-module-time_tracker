# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe BadgeMetrics do
    subject { described_class.new(user) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:) }

    it "raises on unknown metrics" do
      expect { subject.value_for("nonsense") }.to raise_error(ArgumentError)
    end

    describe "completed_activities" do
      before do
        create(:assignation, :completed, activity:, user:)
        create(:assignation, activity: create(:activity, task:), user:)
      end

      it "counts only completed assignations" do
        expect(subject.value_for("completed_activities")).to eq(1)
      end

      context "when scoped to tasks" do
        let(:other_task) { create(:task, time_tracker:) }

        before do
          create(:assignation, :completed, activity: create(:activity, task: other_task), user:)
        end

        it "counts only completions within the given tasks" do
          expect(subject.value_for("completed_activities")).to eq(2)
          expect(subject.value_for("completed_activities", task_ids: [other_task.id])).to eq(1)
          expect(subject.value_for("completed_activities", task_ids: [task.id, other_task.id])).to eq(2)
        end
      end
    end

    describe "skills_earned" do
      let(:other_task) { create(:task, time_tracker:) }

      before do
        create(:skill_certification, user:, task:)
        create(:skill_certification, user:, task: other_task)
      end

      context "when tasks have no explicit skills" do
        it "counts one skill per certified task" do
          expect(subject.value_for("skills_earned")).to eq(2)
        end
      end

      context "when scoped to tasks" do
        it "counts only certifications within the given tasks" do
          expect(subject.value_for("skills_earned", task_ids: [other_task.id])).to eq(1)
        end
      end

      context "when certifications share an explicit skill" do
        let(:skill) { create(:skill, organization:) }

        before do
          SkillCertification.destroy_all
          create(:skill_certification, user:, task:, skill:)
          create(:skill_certification, user:, task: other_task, skill:)
        end

        it "counts distinct skills" do
          expect(subject.value_for("skills_earned")).to eq(1)
        end
      end
    end

    describe "milestones_created" do
      before { create(:milestone, activity:, user:) }

      it "counts the user milestones" do
        expect(subject.value_for("milestones_created")).to eq(1)
      end
    end

    describe "time_dedicated_hours" do
      before do
        assignation = create(:assignation, activity:, user:)
        create(:time_event, assignation:, activity:, user:, start: 2.hours.ago.to_i, stop: Time.current.to_i, total_seconds: 7200)
      end

      it "returns whole hours" do
        expect(subject.value_for("time_dedicated_hours")).to eq(2)
      end
    end
  end
end
