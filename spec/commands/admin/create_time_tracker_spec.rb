# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker::Admin
  describe CreateTimeTracker do
    let(:subject) { described_class.new(component) }

    let(:organization) { create :organization }
    let(:user) { create :user, :admin, :confirmed, organization: organization }
    let(:participatory_process) { create :participatory_process, organization: organization }
    let(:component) { create :time_tracker_component, participatory_space: participatory_process }

    context "when the save command is not successful" do
      let(:component) { nil }

      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the save command is successful" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new time_tracker for the organization" do
        expect { subject.call }.to change { Decidim::TimeTracker::TimeTracker.count }.by(1)
      end

      it "creates an associated questionnaire" do
        expect { subject.call }.to change { Decidim::Forms::Questionnaire.count }.by(1)
      end
    end
  end
end
