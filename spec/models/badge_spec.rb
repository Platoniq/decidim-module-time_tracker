# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Badge do
    subject { badge }

    let(:organization) { create(:organization) }
    let(:levels) { [1, 5, 15, 30] }
    let(:badge) { create(:time_tracker_badge, organization:, levels:) }

    it { is_expected.to be_valid }

    context "when restricted to tasks" do
      let(:task) { create(:task) }

      before { badge.tasks << task }

      it "is associated with the tasks" do
        expect(subject.reload.tasks).to eq([task])
      end

      it "removes the restriction when destroyed" do
        expect { subject.destroy! }.to change(BadgeTask, :count).by(-1)
      end
    end

    it "is invalid with an unknown metric" do
      subject.metric = "nonsense"
      expect(subject).not_to be_valid
    end

    context "with the required_skills metric" do
      let(:skill) { create(:skill, organization:) }

      it "is invalid without skills" do
        subject.metric = "required_skills"
        expect(subject).not_to be_valid
      end

      it "is valid with skills" do
        subject.metric = "required_skills"
        subject.skills << skill
        # One named skill, so only a threshold of 1 can ever be reached.
        subject.levels = [1]
        expect(subject).to be_valid
      end

      it "is invalid when a threshold exceeds the number of required skills" do
        subject.metric = "required_skills"
        subject.skills << skill
        subject.levels = [1, 2]

        expect(subject).not_to be_valid
        expect(subject.errors[:levels]).to be_present
      end

      it "allows a threshold for every named skill" do
        subject.metric = "required_skills"
        subject.skills << skill
        subject.skills << create(:skill, organization:)
        subject.levels = [1, 2]

        expect(subject).to be_valid
      end
    end

    describe ".default_levels" do
      it "returns as many thresholds as levels asked for" do
        expect(described_class.default_levels("completed_activities", 3)).to eq([1, 3, 5])
      end

      it "steps one skill at a time for the required_skills metric" do
        expect(described_class.default_levels("required_skills", 4)).to eq([1, 2, 3, 4])
      end

      it "clamps to the supported range" do
        expect(described_class.default_levels("time_dedicated_hours", 0).size).to eq(1)
        expect(described_class.default_levels("time_dedicated_hours", 99).size).to eq(described_class::MAX_LEVELS)
      end

      it "falls back to a usable curve for an unknown metric" do
        expect(described_class.default_levels("nonsense", 2)).to eq([1, 3])
      end
    end

    it "is invalid with unsorted levels" do
      subject.levels = [5, 1]
      expect(subject).not_to be_valid
    end

    it "is invalid with duplicated levels" do
      subject.levels = [1, 1, 5]
      expect(subject).not_to be_valid
    end

    it "is invalid with non-positive levels" do
      subject.levels = [0, 5]
      expect(subject).not_to be_valid
    end

    describe "#level_for" do
      it "returns 0 below the first threshold" do
        expect(subject.level_for(0)).to eq(0)
      end

      it "returns the reached level" do
        expect(subject.level_for(1)).to eq(1)
        expect(subject.level_for(14)).to eq(2)
        expect(subject.level_for(30)).to eq(4)
        expect(subject.level_for(100)).to eq(4)
      end
    end

    describe "#next_level_threshold" do
      it "returns the next threshold" do
        expect(subject.next_level_threshold(0)).to eq(1)
        expect(subject.next_level_threshold(7)).to eq(15)
      end

      it "returns nil when maxed out" do
        expect(subject.next_level_threshold(30)).to be_nil
      end
    end
  end
end
