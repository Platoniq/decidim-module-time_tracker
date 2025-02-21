# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Activity do
      subject { activity }

      let(:component) { create(:time_tracker_component) }
      let(:time_tracker) { create(:time_tracker, component:, questionnaire:) }
      let(:questionnaire) { create(:questionnaire) }
      let(:task) { create(:task, time_tracker:) }
      let(:activity) { create(:activity, task:) }

      it { is_expected.to be_valid }

      context "when the activity is correctly associated" do
        let!(:assignations) { create_list(:assignation, 2, activity:) }
        let!(:time_events) do
          [
            create(:time_event, activity:, start: 1000),
            create(:time_event, activity:, start: 2000),
            create(:time_event, activity:, start: 3000)
          ]
        end

        it "is associated with a task" do
          expect(subject.task).to eq(task)
        end

        it "is associated with time_events in reverse order" do
          expect(subject.time_events.count).to eq time_events.count
          expect(subject.time_events.first.id).to eq(time_events.third.id)
          expect(subject.time_events.second.id).to eq(time_events.second.id)
          expect(subject.time_events.third.id).to eq(time_events.first.id)
        end

        it "is associated with assignations" do
          expect(subject.assignations.count).to eq assignations.count
          expect(subject.assignations.first.id).to eq(assignations.first.id)
          expect(subject.assignations.second.id).to eq(assignations.second.id)
        end
      end

      context "when activity is inactive" do
        let(:activity) { create(:activity, active: false) }

        it "current status is :inactive" do
          expect(subject.status).to eq(:inactive)
        end
      end

      context "when hasn't started yet" do
        let(:activity) { create(:activity, start_date: (Time.current.beginning_of_day + 1.day)) }

        it "current status is :not_started" do
          expect(subject.status).to eq(:not_started)
        end
      end

      context "when activity has finished" do
        let(:activity) { create(:activity, end_date: (Time.current.beginning_of_day - 1.day)) }

        it "current status is :finished" do
          expect(subject.status).to eq(:finished)
        end
      end

      context "when activity is open for business" do
        it "current status is :open" do
          expect(subject.status).to eq(:open)
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

      context "when the activity has assignations with different statuses" do
        let!(:accepted) { create(:assignation, :accepted, activity:) }
        let!(:rejected) { create(:assignation, :rejected, activity:) }
        let!(:pending) { create(:assignation, :pending, activity:) }

        it "detects accepted assignations" do
          expect(subject.assignation_accepted?(accepted.user)).to be(true)
          expect(subject.assignation_rejected?(accepted.user)).to be(false)
          expect(subject.assignation_pending?(accepted.user)).to be(false)
        end

        it "detects rejected assignations" do
          expect(subject.assignation_accepted?(rejected.user)).to be(false)
          expect(subject.assignation_rejected?(rejected.user)).to be(true)
          expect(subject.assignation_pending?(rejected.user)).to be(false)
        end

        it "detects pending assignations" do
          expect(subject.assignation_accepted?(pending.user)).to be(false)
          expect(subject.assignation_rejected?(pending.user)).to be(false)
          expect(subject.assignation_pending?(pending.user)).to be(true)
        end
      end

      context "when assignation is tracking" do
        let!(:assignation) { create(:assignation, :accepted, activity:) }

        context "and there are no time events" do
          it "detects counter as not active" do
            expect(subject.counter_active_for?(assignation.user)).to be(false)
          end
        end

        context "and counter is not running" do
          let!(:event) { create(:time_event, :stopped, activity:, assignation:) }

          it "detects counter as not active" do
            expect(subject.counter_active_for?(assignation.user)).to be(false)
          end
        end

        context "and counter is running" do
          let!(:first_event) { create(:time_event, :stopped, activity:, assignation:) }
          let!(:second_event) { create(:time_event, :running, activity:, assignation:) }

          it "detects counter as active" do
            expect(subject.counter_active_for?(assignation.user)).to be(true)
          end

          it "detects the number of elapsed seconds" do
            expect(subject.user_seconds_elapsed(assignation.user)).to eq(2.minutes)
          end
        end
      end
    end
  end
end
