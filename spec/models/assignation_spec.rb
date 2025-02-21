# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Assignation do
      subject { assignation }

      let(:organization) { create(:organization) }
      let(:assignation) { create(:assignation, invited_by_user:, user:, activity:) }
      let(:user) { create(:user) }
      let(:invited_by_user) { create(:user) }
      let(:activity) { create(:activity) }

      context "when the assignation is correctly associated" do
        let!(:time_events) { create_list(:time_event, 3, assignation:) }

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

      context "when assignation is accepted" do
        let(:assignation) { create(:assignation, :accepted) }

        it "detects as accepted" do
          expect(subject.accepted?).to be(true)
          expect(subject.rejected?).to be(false)
          expect(subject.pending?).to be(false)
        end
      end

      context "when assignation is rejected" do
        let(:assignation) { create(:assignation, :rejected) }

        it "detects as rejected" do
          expect(subject.accepted?).to be(false)
          expect(subject.rejected?).to be(true)
          expect(subject.pending?).to be(false)
        end
      end

      context "when assignation is pending" do
        let(:assignation) { create(:assignation, :pending) }

        it "detects as pending" do
          expect(subject.accepted?).to be(false)
          expect(subject.rejected?).to be(false)
          expect(subject.pending?).to be(true)
        end
      end

      context "when assignation has time events" do
        let!(:first_event) { create(:time_event, :stopped, assignation:) }
        let!(:second_event) { create(:time_event, :running, assignation:) }

        it "detect the time dedicated" do
          expect(subject.time_dedicated).to eq(1.minute)
        end

        it "detect the time dedicated to activity" do
          expect(subject.time_dedicated_to(activity)).to eq(0)
          expect(subject.time_dedicated_to(first_event.activity)).to eq(1.minute)
        end

        context "and there is more events" do
          let!(:third_event) { create(:time_event, :stopped, assignation:, activity: first_event.activity) }
          let!(:fourth_event) { create(:time_event, :running, assignation:, activity: first_event.activity) }

          it "detect the time dedicated" do
            expect(subject.time_dedicated).to eq(2.minutes)
          end

          it "detect the time dedicated to activity" do
            expect(subject.time_dedicated_to(activity)).to eq(0)
            expect(subject.time_dedicated_to(first_event.activity)).to eq(2.minutes)
          end
        end
      end
    end
  end
end
