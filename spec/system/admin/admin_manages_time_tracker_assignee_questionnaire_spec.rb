# frozen_string_literal: true

require "spec_helper"

describe "Admin manages Time tracker assignee questionnaire" do
  include_context "with a full time_tracker"
  include_context "when managing a component as an admin"

  let(:manifest_name) { "time_tracker" }
  let(:questionnaire) { time_tracker.assignee_questionnaire }

  it_behaves_like "manage questionnaires"
  it_behaves_like "manage questionnaire answers"

  def questionnaire_edit_path
    Decidim::EngineRouter.admin_proxy(component).edit_assignee_questionnaire_path
  end

  def questionnaire_public_path
    Decidim::EngineRouter.main_proxy(component).preview_assignee_questionnaire_path
  end

  def manage_questions_path
    Decidim::EngineRouter.admin_proxy(component).edit_questions_assignee_questionnaire_path
  end

  def update_component_settings_or_attributes; end

  def see_questionnaire_questions; end
end
