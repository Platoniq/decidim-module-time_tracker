# frozen_string_literal: true

shared_context "with a time_tracker" do
  let(:organization) { create(:organization) }
  let(:participatory_space) { create(:participatory_process, organization:) }
  let(:component) { create(:time_tracker_component, participatory_space:) }
  let!(:time_tracker) { create(:time_tracker, component:) }
  let!(:assignee_data) { create(:assignee_data, time_tracker:) }
end

shared_context "with a full time_tracker" do
  include_context "with a time_tracker"

  let!(:task) { create(:task, time_tracker:) }
  let!(:activity) { create(:activity, task:) }
  let!(:assignation) { create(:assignation, user:, activity:) }
  let!(:tos_acceptance) { Decidim::TimeTracker::TosAcceptance.create!(assignee: Decidim::TimeTracker::Assignee.for(user), time_tracker:) }
end
