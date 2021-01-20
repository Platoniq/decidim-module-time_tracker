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

              describe "user logs time for activity" do
                before do
                  page.find(".time-tracker-activity-start").click
                  sleep 1
                end

                it "starts the timer" do
                  expect(page).not_to have_selector ".time-tracker-activity-start"
                  expect(page).to have_selector ".time-tracker-activity-stop"
                  expect(page).to have_selector ".time-tracker-activity-pause"
                end

                it "pauses the timer" do
                  expect(page).not_to have_content "0h0m0s"
                  page.find(".time-tracker-activity-pause").click
                  expect(page).not_to have_selector ".time-tracker-activity-pause"
                  expect(page).to have_selector ".time-tracker-activity-stop"
                  expect(page).to have_selector ".time-tracker-activity-start"
                end

                context "when stopping the timer" do
                  before do
                    page.find(".time-tracker-activity-stop").click
                  end

                  it "stops the timer" do
                    expect(page).not_to have_selector ".time-tracker-activity-stop"
                    expect(page).not_to have_selector ".time-tracker-activity-pause"
                    expect(page).to have_selector ".time-tracker-activity-start"
                    expect(page).to have_content "Leave your mark"

                    within ".milestone" do
                      expect(page).to have_button "Save"
                    end
                  end

                  it "allows submitting a milestone", processing_uploads_for: Decidim::AttachmentUploader do
                    within ".new_milestone" do
                      fill_in "What have you done?", with: "I saved the world from chaos!"
                      fill_in "Description", with: "Specs are the only thing that separate us from barbaric coding"
                      attach_file :milestone_attachment_file, Decidim::Dev.asset("city.jpeg")
                      click_button "Save"
                    end

                    expect(page).to have_current_path milestones_path(nickname: user.nickname)
                    expect(page).to have_content "I saved the world"
                    expect(page).to have_link "Back to activities", href: time_tracker_path
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def component_engine
    Decidim::EngineRouter.main_proxy(component)
  end

  def visit_time_tracker
    visit time_tracker_path
  end

  def time_tracker_path
    component_engine.root_path
  end

  delegate :milestones_path, to: :component_engine

  delegate :assignee_questionnaire_path, to: :component_engine
end
