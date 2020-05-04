# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe TimeEntriesController, type: :controller do
      let(:organization) { create :organization }
      let(:user) { create(:user, :confirmed, :admin, organization: organization) }
      let(:participatory_space) { create(:participatory_process, organization: organization) }
      let(:component) { create :time_tracker_component, participatory_space: participatory_space }
      let(:task) { create :task, component: component }
      let(:activity) { create :activity, task: task }
      let(:assignee) { create :assignee, activity: activity }

      before do
        request.env["decidim.current_organization"] = organization
        request.env["decidim.current_participatory_process"] = participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "post #new" do
        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id
          }
        end

        it "creates a new time entry" do
          post :create, params: params
          # expect(response).to redirect_to(EngineRouter.main_proxy(component).new_task_activity_asignee_path(task, activity))
        end
      end

      describe "patch #update" do
        before do
          let!(:time_entry) { create :time_entry, activity: activity, assignee: assignee }
        end

        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id,
            id: time_entry.id
          }
        end

        it "updates the time entry" do
          patch :update, params: params
          # expect(response).to redirect_to(EngineRouter.main_proxy(component).new_task_activity_asignee_path(task, activity))
        end
      end

      describe "patch #update" do
        before do
          let!(:time_entry) { create :time_entry, activity: activity, assignee: assignee, time_end: nil }
        end

        let(:params) do
          {
            task_id: task.id,
            activity_id: activity.id,
            id: time_entry.id
          }
        end

        it "updates the time entry" do
          patch :update, params: params
          # expect(response).to redirect_to(EngineRouter.main_proxy(component).new_task_activity_asignee_path(task, activity))
        end
      end
    end
  end
end
