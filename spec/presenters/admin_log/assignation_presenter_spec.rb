# frozen_string_literal: true

require "spec_helper"
require "decidim/time_tracker/test/admin_log_presenter_examples"

module Decidim::TimeTracker
  describe AdminLog::AssignationPresenter, type: :helper do
    include_examples "present admin log entry" do
      let(:participatory_space) { create(:participatory_process, organization:) }
      let(:component) { create(:time_tracker_component, participatory_space:) }
      let(:time_tracker) { create(:time_tracker, component:) }
      let(:task) { create(:task, time_tracker:) }
      let(:admin_log_resource) { create(:assignation, task:) }
      let(:action) { "update" }
    end
  end
end
