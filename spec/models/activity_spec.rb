# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Activity do
      subject { activity }

      let(:task) { create(:task) }
      let(:activity) { create(:activity, task: task) }

      it { is_expected.to be_valid }

      context "when the activity is correctly associated" do
        let!(:assignees) { create_list(:assignee, 2, activity: activity) }
        let!(:time_events) do
          [
            create(:time_event, activity: activity, start: 1000),
            create(:time_event, activity: activity, start: 2000),
            create(:time_event, activity: activity, start: 3000)
          ]
        end

        it "is associated with a task" do
          expect(subject.task). to eq(task)
        end

        it "is associated with time_events in reverse order" do
          expect(subject.time_events.count).to eq time_events.count
          expect(subject.time_events.first.id).to eq(time_events.third.id)
          expect(subject.time_events.second.id).to eq(time_events.second.id)
          expect(subject.time_events.third.id).to eq(time_events.first.id)
        end

        it "is associated with assignees" do
          expect(subject.assignees.count).to eq assignees.count
          expect(subject.assignees.first.id).to eq(assignees.first.id)
          expect(subject.assignees.second.id).to eq(assignees.second.id)
        end
      end

      context "when activity is inactive" do
        let(:activity) { create(:activity, active: false) }

        it "current status is :inactive" do
          expect(subject.current_status).to eq(:inactive)
        end
      end

      context "when hasn't started yet" do
        let(:activity) { create(:activity, start_date: (Time.current.beginning_of_day + 1.day)) }

        it "current status is :not_started" do
          expect(subject.current_status).to eq(:not_started)
        end
      end

      context "when activity has finished" do
        let(:activity) { create(:activity, end_date: (Time.current.beginning_of_day - 1.day)) }

        it "current status is :finished" do
          expect(subject.current_status).to eq(:finished)
        end
      end

      context "when activity is open for business" do
        it "current status is :open" do
          expect(subject.current_status).to eq(:open)
        end
      end

      context "when the task has questions" do
        let!(:question) { create(:questionnaire_question, questionnaire: subject.questionnaire, position: 0) }

        it "activity has questions" do
          expect(subject.has_questions?).to be true
        end
      end

      context "when the activity has no questions" do
        it "activity has no questions" do
          expect(subject.has_questions?).to be false
        end
      end

      context "when the activity has assignees with different statuses" do
        let!(:accepted) { create :assignee, :accepted, activity: activity }
        let!(:rejected) { create :assignee, :rejected, activity: activity }
        let!(:pending) { create :assignee, :pending, activity: activity }

        it "detects accepted assignees" do
          expect(subject.assignee_accepted?(accepted.user)).to eq(true)
          expect(subject.assignee_rejected?(accepted.user)).to eq(false)
          expect(subject.assignee_pending?(accepted.user)).to eq(false)
        end

        it "detects rejected assignees" do
          expect(subject.assignee_accepted?(rejected.user)).to eq(false)
          expect(subject.assignee_rejected?(rejected.user)).to eq(true)
          expect(subject.assignee_pending?(rejected.user)).to eq(false)
        end

        it "detects pending assignees" do
          expect(subject.assignee_accepted?(pending.user)).to eq(false)
          expect(subject.assignee_rejected?(pending.user)).to eq(false)
          expect(subject.assignee_pending?(pending.user)).to eq(true)
        end
      end

      context "when assignee is tracking" do
        let!(:assignee) { create :assignee, :accepted, activity: activity }

        context "and there are no time events" do
          it "detects counter as not active" do
            expect(subject.counter_active_for?(assignee.user)).to eq(false)
          end
        end

        context "and counter is not running" do
          let!(:event) { create :time_event, :stopped, activity: activity, assignee: assignee }

          it "detects counter as not active" do
            expect(subject.counter_active_for?(assignee.user)).to eq(false)
          end
        end

        context "and counter is running" do
          let!(:event1) { create :time_event, :stopped, activity: activity, assignee: assignee }
          let!(:event2) { create :time_event, :running, activity: activity, assignee: assignee }

          it "detects counter as active" do
            expect(subject.counter_active_for?(assignee.user)).to eq(true)
          end

          it "detects the number of elapsed seconds" do
            expect(subject.user_seconds_elapsed(assignee.user)).to eq(2.minutes)
          end
        end
      end
    end
  end
end
