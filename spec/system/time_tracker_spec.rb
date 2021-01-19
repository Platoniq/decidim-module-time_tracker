# frozen_string_literal: true

require "spec_helper"

describe "Time tracker page", type: :system do
  let(:organization) { create :organization }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:participatory_space) { create(:participatory_process, organization: organization) }
  let(:component) { create :time_tracker_component, participatory_space: participatory_space }
  let!(:time_tracker) { create :time_tracker, component: component }

  before do
    switch_to_host(user.organization.host)
  end

  shared_examples "renders 'no activities' callout" do
    before do
      visit_time_tracker
    end

    it "shows a callout" do
      expect(page).to have_content("no activities")
    end
  end

  shared_examples "renders activity list" do
    before do
      visit_time_tracker
    end

    it "shows task name" do
      expect(page).to have_content(time_tracker.tasks.first.name["en"].upcase)
    end

    it "shows activity description" do
      expect(page).to have_i18n_content(time_tracker.activities.first.description)
    end
  end

  shared_examples "renders links to fill in demographic data" do
    before do
      visit_time_tracker
    end

    it "renders 'let's start' callout" do
      within ".time-tracker--assignee-data" do
        expect(page).to have_link "Let's start!", href: assignee_questionnaire_path
      end
    end

    it "renders 'terms of use' callout next to activities" do
      within "#activities .time-tracker-request" do
        within ".callout.warning" do
          expect(page).to have_link "terms of use", href: assignee_questionnaire_path
        end
      end
    end
  end

  shared_examples "does not render 'let's start' callout" do
    it "does not render 'let's start' callout" do
      visit_time_tracker
      expect(page).not_to have_selector ".time-tracker--assignee-data"
      expect(page).not_to have_link "Let's start!", href: assignee_questionnaire_path
    end
  end

  context "when visiting time tracker page" do
    context "when user is not logged" do
      context "when there are no activities" do
        it_behaves_like "renders 'no activities' callout"
        it_behaves_like "does not render 'let's start' callout"
      end

      context "when there are activities" do
        let!(:task) { create(:task, time_tracker: time_tracker) }
        let!(:activity) { create(:activity, task: task) }

        it_behaves_like "renders activity list"
        it_behaves_like "does not render 'let's start' callout"
      end
    end

    context "when user is logged" do
      before do
        login_as user, scope: :user
      end

      context "when there are no activities" do
        it_behaves_like "renders 'no activities' callout"
        it_behaves_like "does not render 'let's start' callout"
      end

      context "when there are activities" do
        let!(:task) { create(:task, time_tracker: time_tracker) }
        let!(:activity) { create(:activity, task: task) }

        it_behaves_like "renders activity list"
        it_behaves_like "renders links to fill in demographic data"
      end
    end
  end

  def visit_time_tracker
    visit Decidim::EngineRouter.main_proxy(component).root_path
  end

  def assignee_questionnaire_path
    Decidim::EngineRouter.main_proxy(component).assignee_questionnaire_path
  end
end
