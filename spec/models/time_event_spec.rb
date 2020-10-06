# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeEvent do
      subject { time_event }

      let(:time_event) { create(:time_event, assignee: assignee, activity: activity, user: assignee.user) }
      let!(:assignee) { create(:assignee) }
      let!(:activity) { create(:activity) }

      context "when the time entry is correctly associated" do
        it "belongs to an assignee" do
          expect(subject.assignee).to eq(assignee)
        end

        it "belongs to an activity" do
          expect(subject.activity.id).to eq(activity.id)
        end

        it "belongs to a Decidim user" do
          expect(subject.user).to be_a Decidim::User
          expect(subject.user).to eq(assignee.user)
        end
      end
    end
  end
end
