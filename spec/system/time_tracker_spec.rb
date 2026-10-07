# frozen_string_literal: true

require "spec_helper"

describe "Time tracker page" do
  include_context "with a time_tracker"

  let(:user) { create(:user, :confirmed, organization:) }

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
      expect(page).to have_content(time_tracker.tasks.first.name["en"])
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

    it "sends the Join button to the terms first" do
      within ".time-tracker__activity" do
        expect(page).to have_link "Join", href: assignee_questionnaire_path
      end
    end
  end

  shared_examples "does not render links to fill in demographic data" do
    before do
      visit_time_tracker
    end

    it "does not render 'let's start' callout" do
      expect(page).to have_no_css ".time-tracker--assignee-data"
      expect(page).to have_no_link "Let's start!", href: assignee_questionnaire_path
    end

    it "does not render any link to assignee questionnaire" do
      expect(page).to have_no_css("[href=\"#{assignee_questionnaire_path}\"]")
    end
  end

  context "when visiting time tracker page" do
    context "when user is not logged" do
      context "when there are no activities" do
        it_behaves_like "renders 'no activities' callout"
        it_behaves_like "does not render links to fill in demographic data"
      end

      context "when there are activities" do
        let!(:task) { create(:task, time_tracker:) }
        let!(:activity) { create(:activity, task:) }

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
        let!(:task) { create(:task, time_tracker:) }
        let!(:activity) { create(:activity, task:) }

        it_behaves_like "renders activity list"

        context "when user has not accepted terms" do
          before { create(:questionnaire_question, questionnaire: assignee_data.questionnaire) }

          it_behaves_like "renders links to fill in demographic data"
        end

        context "when the time tracker asks nothing before joining" do
          before do
            login_as user, scope: :user
            visit_time_tracker
          end

          it_behaves_like "does not render links to fill in demographic data"

          it "registers the request with one click" do
            within ".time-tracker__activity" do
              click_on "Join"

              expect(page).to have_css(".time-tracker__state--pending", text: "registered")
            end
            expect(Decidim::TimeTracker::Assignation.find_by(user:, activity:)).to be_pending
          end
        end

        context "when user has accepted terms" do
          before do
            Decidim::TimeTracker::TosAcceptance.create!(assignee: Decidim::TimeTracker::Assignee.for(user), time_tracker:)
            login_as user, scope: :user
            visit_time_tracker
          end

          it_behaves_like "does not render links to fill in demographic data"

          describe "user signs up for activity" do
            it "allows joining activity" do
              within ".time-tracker__activity" do
                click_on "Join"

                expect(page).to have_css(".time-tracker__state--pending", text: "registered")
              end
              expect(Decidim::TimeTracker::Assignation.find_by(user:, activity:)).to be_pending
            end
          end

          context "when user is signed up for activity" do
            let!(:assignation) { create(:assignation, user:, activity:, status:) }

            before do
              visit_time_tracker
            end

            context "when status is pending" do
              let(:status) { :pending }

              it "shows that the request is waiting" do
                within ".time-tracker__activity" do
                  expect(page).to have_css(".time-tracker__state--pending", text: "Request sent")
                end
              end
            end

            context "when status is rejected" do
              let(:status) { :rejected }

              it "shows that the request was turned down" do
                within ".time-tracker__activity" do
                  expect(page).to have_css(".time-tracker__state--rejected", text: "Not accepted")
                end
              end
            end

            context "when status is accepted" do
              let(:status) { :accepted }

              it "puts the activity's timer under Your activities" do
                within "#my-activities .time-tracker-activity" do
                  expect(page).to have_content "0:00:00"
                  expect(page).to have_button "Start"
                end

                within ".time-tracker__activity" do
                  expect(page).to have_link "You're in — track time", href: "#activity-#{activity.id}"
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
