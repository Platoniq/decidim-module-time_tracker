# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe SkillCertification do
    subject { skill_certification }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:skill_certification) { create(:skill_certification, user:, task:) }

    it { is_expected.to be_valid }

    it "is associated with a user" do
      expect(subject.user).to eq(user)
    end

    it "is associated with a task" do
      expect(subject.task).to eq(task)
    end

    describe "#skill_name" do
      it "returns the task name" do
        expect(subject.skill_name).to eq(task.name)
      end
    end

    context "when the same user is already certified for the same task" do
      before { skill_certification }

      it "is not valid" do
        duplicate = build(:skill_certification, user:, task:)
        expect(duplicate).not_to be_valid
      end
    end

    context "when a different user is certified for the same task" do
      let(:other_user) { create(:user, organization:) }

      it "is valid" do
        other = build(:skill_certification, user: other_user, task:)
        expect(other).to be_valid
      end
    end
  end
end
