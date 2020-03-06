# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeEntry do
      subject { time_entry }

      let(:time_entry) { create(:time_entry, assignee: assignee, milestone: milestone, activity: activity, validated_by_user: validated_by_user) }
      let!(:assignee) { create(:assignee) }
      let!(:milestone) { create(:milestone) }
      let!(:activity) { create(:activity) }
      let!(:validated_by_user) { create(:user) }

      context "when the time entry is correctly associated" do
        it "belongs to an assignee" do
          expect(subject.assignee.id).to eq(assignee.id)
        end

        it "belongs to a milestone" do
          expect(subject.milestone.id).to eq(milestone.id)
        end

        it "belongs to an activity" do
          expect(subject.activity.id).to eq(activity.id)
        end

        it "has been validated by a user" do
          expect(subject.validated_by_user.id).to eq(validated_by_user.id)
        end
      end
    end
  end
end
