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
        expect(subject).to be_valid
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
