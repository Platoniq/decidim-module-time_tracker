# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe CreateMilestone do
    subject { described_class.new(form, user) }

    let(:activity) { create(:activity, max_minutes_per_day: 60) }
    let(:user) { create(:user, :confirmed, organization:) }
    let(:assignation) { create(:assignation, user:, activity:, status:) }
    let(:organization) { create(:organization) }

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

    it "emails the space's admins about the update" do
      allow(Decidim::EventsManager).to receive(:publish)
      subject.call

      expect(Decidim::EventsManager).to have_received(:publish).with(
        hash_including(event: "decidim.events.time_tracker.milestone_created_event",
                       event_class: Decidim::TimeTracker::MilestoneCreatedEvent,
                       resource: activity,
                       extra: { participant_name: user.name, force_email: true })
      )
    end
  end
end
