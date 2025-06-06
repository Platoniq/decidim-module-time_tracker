# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe TimeEventsController do
    routes { Decidim::TimeTracker::Engine.routes }

    include_context "with a time_tracker"

    let(:user) { create(:user, :confirmed, organization:) }

    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:) }
    let!(:assignation) { create(:assignation, activity:, user:) }

    let(:params) do
      {
        task_id: task.id,
        activity_id: activity.id
      }
    end

    before do
      # Mock Time.current to have a predictable time
      allow(Time).to receive(:current).and_return(Date.current + 12.hours)

      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_space
      request.env["decidim.current_component"] = component
      sign_in user
    end

    describe "post #start" do
      context "when is a new entry" do
        it "creates a new time event" do
          get(:start, params:)
          expect(response).to have_http_status(:success)

          resp = response.parsed_body
          last = Decidim::TimeTracker::TimeEvent.first # default scope is order by :desc

          expect(resp["id"]).to eq(last.id)
          expect(resp["start"]).to eq(Time.current.to_i)
          expect(resp["startTime"].to_time).to eq(Time.current)
        end
      end

      context "when a previous counter exists" do
        let!(:time_event) { create(:time_event, start: 15.minutes.ago, assignation:, activity:) }

        it "returns already active" do
          get(:start, params:)
          expect(response).to have_http_status(:success)

          resp = response.parsed_body
          expect(resp["id"]).to eq(time_event.id)
          expect(resp["error"]).to eq("Counter already started")
        end
      end

      context "when the assignation is not in the activity" do
        let(:assignation) { create(:assignation, user:) }

        it "returns error" do
          get(:start, params:)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when the assignation is not accepted in the activity" do
        let(:assignation) { create(:assignation, :pending, activity:, user:) }

        it "returns error" do
          get(:start, params:)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when the assignation is not in the time window for the activity" do
        let(:activity) { create(:activity, task:, start_date: 1.day.from_now) }

        it "returns error" do
          get(:start, params:)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "post #stop" do
      let!(:time_event) { create(:time_event, start: 1.hour.ago, activity:, assignation:) }

      context "when counter is active" do
        it "stops the time entry" do
          get(:stop, params:)
          resp = response.parsed_body
          entry = JSON.parse(resp["timeEvent"])

          expect(response).to have_http_status(:success)
          expect(entry["id"]).to eq(time_event.id)
          expect(entry["start"]).to eq(time_event.start)
          expect(entry["stop"]).to eq(Time.current.to_i)
          expect(entry["total_seconds"]).to eq(3600)
        end
      end

      context "when counter is stopped" do
        let!(:time_event) { create(:time_event, start: 1.hour.ago, stop: 15.minutes.ago, activity:, assignation:) }

        it "returns already stopped" do
          get(:stop, params:)
          expect(response).to have_http_status(:success)

          resp = response.parsed_body
          expect(resp["error"]).to eq("Counter already stopped")
        end
      end
    end
  end
end
