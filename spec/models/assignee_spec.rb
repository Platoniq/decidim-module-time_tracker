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
        let!(:time_events) { create_list(:time_event, 3, assignee: assignee) }

        it "belongs to an activity" do
          expect(subject.activity.id).to eq(activity.id)
        end

        it "is has time events" do
          expect(subject.time_events.count).to eq(time_events.count)
        end

        it "belongs to a user" do
          expect(subject.user.id).to eq(user.id)
        end

        it "is invited by a user" do
          expect(subject.invited_by_user.id).to eq(invited_by_user.id)
        end
      end

      context "when assignee is accepted" do
        let(:assignee) { create :assignee, :accepted }

        it "detects as accepted" do
          expect(subject.accepted?).to eq(true)
          expect(subject.rejected?).to eq(false)
          expect(subject.pending?).to eq(false)
        end
      end

      context "when assignee is rejected" do
        let(:assignee) { create :assignee, :rejected }

        it "detects as rejected" do
          expect(subject.accepted?).to eq(false)
          expect(subject.rejected?).to eq(true)
          expect(subject.pending?).to eq(false)
        end
      end

      context "when assignee is pending" do
        let(:assignee) { create :assignee, :pending }

        it "detects as pending" do
          expect(subject.accepted?).to eq(false)
          expect(subject.rejected?).to eq(false)
          expect(subject.pending?).to eq(true)
        end
      end

      context "when assignee has time events" do
        let!(:event1) { create :time_event, :stopped, assignee: assignee }
        let!(:event2) { create :time_event, :running, assignee: assignee }

        it "detect the time dedicated" do
          expect(subject.time_dedicated).to eq(1.minute)
        end

        it "detect the time dedicated to activity" do
          expect(subject.time_dedicated_to(activity)).to eq(0)
          expect(subject.time_dedicated_to(event1.activity)).to eq(1.minute)
        end

        context "and there is more events" do
          let!(:event3) { create :time_event, :stopped, assignee: assignee, activity: event1.activity }
          let!(:event4) { create :time_event, :running, assignee: assignee, activity: event1.activity }

          it "detect the time dedicated" do
            expect(subject.time_dedicated).to eq(2.minutes)
          end

          it "detect the time dedicated to activity" do
            expect(subject.time_dedicated_to(activity)).to eq(0)
            expect(subject.time_dedicated_to(event1.activity)).to eq(2.minutes)
          end
        end
      end
    end
  end
end
