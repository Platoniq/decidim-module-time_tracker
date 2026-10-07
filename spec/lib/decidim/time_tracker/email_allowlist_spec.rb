# frozen_string_literal: true

require "spec_helper"

describe Decidim::TimeTracker::EmailAllowlist do
  let(:organization) { create(:organization) }
  let(:listed) { create(:user, :confirmed, organization:, email: "harrison@example.org") }
  let(:colleague) { create(:user, :confirmed, organization:, email: "colleague@example.org") }
  let(:time_tracker) { create(:time_tracker, component: create(:time_tracker_component, participatory_space: create(:participatory_process, organization:))) }
  let(:activity) { create(:activity, task: create(:task, time_tracker:)) }
  let(:time_tracker_event) { ["decidim.events.time_tracker.assignation_requested_event", "Decidim::TimeTracker::AssignationRequestedEvent"] }
  let(:other_event) { ["decidim.events.users.profile_updated", "Decidim::ProfileUpdatedEvent"] }
  let(:allowlist) { "Harrison@example.org, " }

  around do |example|
    previous = Decidim::TimeTracker.email_allowlist
    Decidim::TimeTracker.email_allowlist = allowlist
    example.run
  ensure
    Decidim::TimeTracker.email_allowlist = previous
  end

  def notification_mail(event, user, resource)
    Decidim::NotificationMailer.event_received(event.first, event.last, resource, user, :affected_user, { participant_name: "Ollie" })
  end

  describe "single notification emails" do
    it "sends Time Tracker emails to listed addresses, whatever their case" do
      expect(notification_mail(time_tracker_event, listed, activity).to).to eq([listed.email])
    end

    it "sends no Time Tracker email to anyone else" do
      expect(notification_mail(time_tracker_event, colleague, activity).message).to be_a(ActionMailer::Base::NullMail)
    end

    it "leaves other Decidim emails alone" do
      expect(notification_mail(other_event, colleague, colleague).to).to eq([colleague.email])
    end

    context "when the list is empty" do
      let(:allowlist) { "" }

      it "emails everyone as before" do
        expect(notification_mail(time_tracker_event, colleague, activity).to).to eq([colleague.email])
      end
    end
  end

  describe "the notifications digest" do
    let!(:time_tracker_notification) do
      create(:notification, user: colleague, resource: activity, event_name: time_tracker_event.first, event_class: time_tracker_event.last,
                            extra: { participant_name: "Ollie" })
    end

    it "drops Time Tracker notifications for anyone off the list, and sends nothing if none remain" do
      mail = Decidim::NotificationsDigestMailer.digest_mail(colleague, [time_tracker_notification.id])

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end

    it "keeps them for listed addresses" do
      listed_notification = create(:notification, user: listed, resource: activity, event_name: time_tracker_event.first,
                                                  event_class: time_tracker_event.last, extra: { participant_name: "Ollie" })

      expect(Decidim::NotificationsDigestMailer.digest_mail(listed, [listed_notification.id]).to).to eq([listed.email])
    end
  end
end
