# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe CreateMilestone do
    subject { described_class.new(form, user) }

    let(:activity) { create :activity, max_minutes_per_day: 60 }
    let(:user) { create :user, :confirmed, organization: organization }
    let(:assignation) { create :assignation, user: user, activity: activity, status: status }
    let(:organization) { create :organization }

    let(:form) do
      MilestoneForm.from_params(attributes)
    end

    let(:attributes) do
      {
        activity_id: activity.id,
        title: "My milestone"
      }
    end

    it "broadcasts ok" do
      expect { subject.call }.to broadcast(:ok)
    end
  end
end
