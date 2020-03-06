# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Assignee do
      subject { assignee }

      let(:organization) { create(:organization) }
      let(:assignee) { create(:assignee, invited_by_user: invited_by_user, user: user, activity: activity) }
      let(:user) { create(:user) }
      let(:invited_by_user) { create(:user) }
      let(:activity) { create(:activity) }

      context "when the assignee is correctly associated" do
        let!(:time_entries) { create_list(:time_entry, 3, assignee: assignee) }

        it "belongs to an activity" do
          expect(subject.activity.id).to eq(activity.id)
        end

        it "is has time entries" do
          expect(subject.time_entries.count).to eq(time_entries.count)
        end

        it "belongs to a user" do
          expect(subject.user.id).to eq(user.id)
        end

        it "is invited by a user" do
          expect(subject.invited_by_user.id).to eq(invited_by_user.id)
        end
      end
    end
  end
end
