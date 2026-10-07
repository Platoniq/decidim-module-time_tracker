# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Permissions do
    subject { described_class.new(user, permission_action, context).permissions.allowed? }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:context) do
      {
        current_organization: organization
      }
    end
    let(:permission_action) { Decidim::PermissionAction.new(**action) }

    context "when scope is admin" do
      let(:action) do
        { scope: :admin, action: :read, subject: :template }
      end

      it_behaves_like "permission is not set"
    end

    context "when no user present" do
      let(:action) do
        { scope: :public, action: :read, subject: :template }
      end
      let(:user) { nil }

      it_behaves_like "permission is not set"
    end

    context "when subject is questionnaire" do
      context "and action is not answer" do
        let(:action) do
          { scope: :public, action: :read, subject: :questionnaire }
        end

        it_behaves_like "permission is not set"
      end

      context "and action is answer" do
        let(:action) do
          { scope: :public, action: :answer, subject: :questionnaire }
        end

        it_behaves_like "permission is not set"

        context "and component is published" do
          let(:context) do
            {
              current_component: double(published?: true)
            }
          end

          it { is_expected.to be true }
        end
      end
    end

    context "when subject is assignation" do
      context "and there is no activity present" do
        let(:action) do
          { scope: :public, action: :create, subject: :assignation }
        end

        it { is_expected.to be true }
      end

      context "and there activity is defined" do
        let(:activity) { create(:activity) }
        let(:context) do
          {
            current_organization: organization,
            activity:
          }
        end
        let(:action) do
          { scope: :public, action: :create, subject: :assignation }
        end

        context "and action is not create" do
          let(:action) do
            { scope: :public, action: :read, subject: :assignation }
          end

          it_behaves_like "permission is not set"
        end

        context "and action is create" do
          context "and user is assigned" do
            let!(:assignation) { create(:assignation, activity:, user:) }

            it_behaves_like "permission is not set"
          end

          context "and user is not assigned" do
            let!(:assignation) { create(:assignation, user:) }

            before do
              Decidim::TimeTracker::TosAcceptance.create!(
                assignee: Decidim::TimeTracker::Assignee.for(user),
                time_tracker: activity.task.time_tracker
              )
            end

            it { is_expected.to be true }

            context "and activity is not open" do
              let(:activity) { create(:activity, :closed) }

              it_behaves_like "permission is not set"
            end

            context "and requests have not opened yet" do
              let(:activity) { create(:activity, start_date: 1.week.from_now, requests_start_at: 2.days.from_now) }

              it_behaves_like "permission is not set"
            end
          end

          context "and user has not accepted the time tracker's terms" do
            before do
              assignee_data = create(:assignee_data, time_tracker: activity.task.time_tracker)
              create(:questionnaire_question, questionnaire: assignee_data.questionnaire)
            end

            it_behaves_like "permission is not set"
          end

          context "and the time tracker asks volunteers nothing before joining" do
            before { create(:assignee_data, time_tracker: activity.task.time_tracker) }

            it { is_expected.to be true }
          end
        end
      end
    end

    context "when subject is milestone" do
      context "and there is no activity present" do
        let(:action) do
          { scope: :public, action: :create, subject: :milestone }
        end

        it_behaves_like "permission is not set"

        context "and action is show" do
          let(:action) do
            { scope: :public, action: :show, subject: :milestone }
          end

          it { is_expected.to be true }
        end
      end

      context "and there activity is defined" do
        let(:activity) { create(:activity) }
        let(:context) do
          {
            current_organization: organization,
            activity:
          }
        end
        let(:action) do
          { scope: :public, action: :create, subject: :milestone }
        end

        context "and action is not create" do
          let(:action) do
            { scope: :public, action: :read, subject: :milestone }
          end

          it_behaves_like "permission is not set"
        end

        context "and action is create" do
          context "and user is assigned" do
            let!(:assignation) { create(:assignation, activity:, user:) }

            it { is_expected.to be true }
          end

          context "and user is not assigned" do
            let!(:assignation) { create(:assignation, user:) }

            it_behaves_like "permission is not set"

            context "and activity is inactive" do
              let(:activity) { create(:activity, :inactive) }

              it_behaves_like "permission is not set"
            end
          end
        end
      end
    end
  end
end
