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

  shared_examples "does not render links to fill in demographic data" do
    before do
      visit_time_tracker
    end

    it "does not render 'let's start' callout" do
      expect(page).not_to have_selector ".time-tracker--assignee-data"
      expect(page).not_to have_link "Let's start!", href: assignee_questionnaire_path
    end

    it "does not render any link to assignee questionnaire" do
      expect(page).not_to have_selector("[href=\"#{assignee_questionnaire_path}\"]")
    end
  end

  context "when visiting time tracker page" do
    context "when user is not logged" do
      context "when there are no activities" do
        it_behaves_like "renders 'no activities' callout"
        it_behaves_like "does not render links to fill in demographic data"
      end

      context "when there are activities" do
        let!(:task) { create(:task, time_tracker: time_tracker) }
        let!(:activity) { create(:activity, task: task) }

        it_behaves_like "renders activity list"
        it_behaves_like "does not render links to fill in demographic data"
      end
    end

    context "when user is logged" do
      before do
        login_as user, scope: :user
      end

      context "when there are no activities" do
        it_behaves_like "renders 'no activities' callout"
        it_behaves_like "does not render links to fill in demographic data"
      end

      context "when there are activities" do
        let!(:task) { create(:task, time_tracker: time_tracker) }
        let!(:activity) { create(:activity, task: task) }

        it_behaves_like "renders activity list"

        context "when user has not accepted terms" do
          it_behaves_like "renders links to fill in demographic data"
        end

        context "when user has accepted terms" do
          before do
            Decidim::TimeTracker::TosAcceptance.create!(assignee: Decidim::TimeTracker::Assignee.for(user), time_tracker: time_tracker)
            login_as user, scope: :user
            visit_time_tracker
          end

          it_behaves_like "does not render links to fill in demographic data"

          describe "user signs up for activity" do
            it "allows joining activity" do
              expect(page).to have_button "Request to join activity"

              click_button "Request to join activity"

              within "#activities .time-tracker-request" do
                within ".callout.success" do
                  expect(page).to have_content "successfully"
                end
              end
            end
          end

          context "when user is signed up for activity" do
            let!(:assignation) { create(:assignation, user: user, activity: activity, status: status) }

            before do
              visit_time_tracker
            end

            context "when status is pending" do
              let(:status) { :pending }

              it "shows a callout with the correct message" do
                within "#activities .time-tracker-request" do
                  within ".callout.warning" do
                    expect(page).to have_content "Already applied"
                  end
                end
              end
            end

            context "when status is rejected" do
              let(:status) { :rejected }

              it "shows a callout with the correct message" do
                within "#activities .time-tracker-request" do
                  within ".callout.alert" do
                    expect(page).to have_content "rejected"
                  end
                end
              end
            end

            context "when status is accepted" do
              let(:status) { :accepted }

              it "shows a callout with the correct message" do
                within ".time-tracker-activity" do
                  expect(page).to have_content "Time elapsed"
                  expect(page).to have_content "0h0m0s"
                end
              end
            end
          end
        end
      end
    end
  end

  def visit_time_tracker
    visit time_tracker_path
  end

  def time_tracker_path
    Decidim::EngineRouter.main_proxy(component).root_path
  end

  def assignee_questionnaire_path
    Decidim::EngineRouter.main_proxy(component).assignee_questionnaire_path
  end
end
