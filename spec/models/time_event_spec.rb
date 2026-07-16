# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeEvent do
      subject { time_event }

      let(:time_event) { create(:time_event, assignation:, activity:, user: assignation.user) }
      let!(:assignation) { create(:assignation) }
      let!(:activity) { create(:activity) }

      context "when the time entry is correctly associated" do
        it "belongs to an assignation" do
          expect(subject.assignation).to eq(assignation)
        end

        it "belongs to an activity" do
          expect(subject.activity.id).to eq(activity.id)
        end

        it "belongs to a Decidim user" do
          expect(subject.user).to be_a Decidim::User
          expect(subject.user).to eq(assignation.user)
        end
      end

      describe "#stop! completion criteria" do
        let!(:activity) { create(:activity, min_events: 2, min_duration_minutes_per_event: 10) }
        let!(:assignation) { create(:assignation, :accepted, activity:) }
        let(:user) { assignation.user }

        def track!(minutes)
          event = create(:time_event, assignation:, activity:, user:, start: (minutes * 60).seconds.ago.to_i, stop: nil, total_seconds: 0)
          event.stop!
        end

        it "files a pending completion for every batch of qualifying sessions" do
          expect { track!(30) }.not_to change(ActivityCompletion, :count)
          expect { track!(30) }.to change(ActivityCompletion.pending, :count).by(1)
          expect { track!(30) }.not_to change(ActivityCompletion, :count)
          expect { track!(30) }.to change(ActivityCompletion.pending, :count).by(1)
        end

        it "ignores sessions shorter than the minimum duration" do
          expect { track!(5) }.not_to change(ActivityCompletion, :count)
          expect { track!(30) }.not_to change(ActivityCompletion, :count)
        end

        it "does not complete the assignation or award scores by itself" do
          track!(30)
          track!(30)

          expect(assignation.reload.completed_at).to be_nil
          expect(Decidim::Gamification.status_for(user, :time_tracker_activities).score).to eq(0)
        end
      end
    end
  end
end
