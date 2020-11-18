# frozen_string_literal: true

require "spec_helper"

describe "Admin manages time_tracker", type: :system do
  let(:manifest_name) { "time_tracker" }
  let!(:questionnaire) { create(:questionnaire) }
  let!(:time_tracker) { create :time_tracker, component: component, questionnaire: questionnaire }
  let!(:task) { create :task, time_tracker: time_tracker }
  let!(:activity) { create :activity, task: task }

  include_context "when managing a component as an admin"

  context "when editing questionnaire" do
    before do
      visit questionnaire_edit_path
    end

    it_behaves_like "manage questionnaires"
  end

  it_behaves_like "export time tracker questionnaire answers"

  def questionnaire_edit_path
    Decidim::EngineRouter.admin_proxy(component).edit_questionnaire_path
  end

  def questionnaire_public_path
    Decidim::EngineRouter.main_proxy(component).answer_task_activity_form_path(task_id: task.id, activity_id: activity.id, id: activity.questionnaire)
  end
end
