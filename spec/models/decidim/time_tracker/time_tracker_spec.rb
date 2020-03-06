# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeTracker do
      subject { time_tracker }

      let(:time_tracker) { create(:time_tracker) }

      include_examples "has component"

      it { is_expected.to be_valid }

      context "when the time_tracker is correctly associated" do
        let!(:tasks) { create_list(:task, 3, time_tracker: time_tracker) }
        let!(:milestones) { create_list(:milestone, 3, time_tracker: time_tracker) }

        it "is associated with tasks" do
          expect(subject.tasks.first.id).to eq(tasks.first.id)
          expect(subject.tasks.second.id).to eq(tasks.second.id)
          expect(subject.tasks.third.id).to eq(tasks.third.id)
        end

        it "is associated with milestones" do
          expect(subject.milestones.first.id).to eq(milestones.first.id)
          expect(subject.milestones.second.id).to eq(milestones.second.id)
          expect(subject.milestones.third.id).to eq(milestones.third.id)
        end
      end
    end
  end
end
