# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeEntriesController, type: :controller do
      routes { Decidim::TimeTracker::Engine.routes }

      let(:organization) { create :organization }
      let(:user) { create(:user, :confirmed, :admin, organization: organization) }
      let(:participatory_space) { create(:participatory_process, organization: organization) }
      let(:component) { create :time_tracker_component, participatory_space: participatory_space }
      let(:task) { create :task, component: component }
      let(:activity) { create :activity, task: task }
      let!(:assignee) { create :assignee, activity: activity, user: user }

      before do
        request.env["decidim.current_organization"] = organization
        request.env["decidim.current_participatory_space"] = participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "post #new" do
        let(:time_entry) do
          {
            time_start: 1.hour.ago
          }
        end

        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id,
            time_entry: time_entry
          }
        end

        it "creates a new time entry" do
          post :create, params: params
          expect(JSON.parse(response.body)["time_start"].to_time.iso8601).to eq(time_entry[:time_start].to_time.iso8601)
        end
      end

      describe "patch #update" do
        let!(:time_entry) { create :time_entry, activity: activity, assignee: assignee }
        let(:new_time_entry) do
          {
            id: time_entry.id,
            time_start: time_entry.time_start,
            time_end: 1.second.ago
          }
        end

        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id,
            id: time_entry.id,
            time_entry: new_time_entry
          }
        end

        it "updates the time entry" do
          patch :update, params: params
          expect(JSON.parse(response.body)["time_end"].to_time.iso8601).to eq(new_time_entry[:time_end].to_time.iso8601)
        end
      end
    end
  end
end
