# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker activity questionnaire" do
  include_context "with a full time_tracker"
  include_context "when managing a component as an admin"

  let(:manifest_name) { "time_tracker" }
  let(:questionnaire) { time_tracker.activity_questionnaire }

  it_behaves_like "manage questionnaires"
  it_behaves_like "manage questionnaire answers"

  def questionnaire_edit_path
    Decidim::EngineRouter.admin_proxy(component).edit_activity_questionnaire_path
  end

  def questionnaire_public_path
    Decidim::EngineRouter.main_proxy(component).preview_task_activity_form_path(task_id: activity.task, activity_id: activity, id: activity.questionnaire)
  end
end
