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
  end
end
