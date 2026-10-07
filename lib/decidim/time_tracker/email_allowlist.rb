# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Keeps Time Tracker emails on demo and staging instances from reaching
    # real people other than the ones listed.
    #
    # Those instances are full of seeded volunteers and test accounts, and
    # their organization admins are real colleagues and partners who do not
    # want a mail for every join request or completion someone demoes. When
    # `Decidim::TimeTracker.email_allowlist` lists addresses (the
    # TIME_TRACKER_EMAIL_ALLOWLIST variable, comma separated), Time Tracker
    # notifications are emailed only to those addresses, both one by one and
    # inside the notifications digest. Everyone keeps the in-app
    # notification, and no other Decidim email is affected. With the list
    # empty (the default) nothing changes.
    module EmailAllowlist
      EVENT_PREFIX = "Decidim::TimeTracker::"

      def self.addresses
        Array(Decidim::TimeTracker.email_allowlist).flat_map { |entry| entry.to_s.split(",") }
                                                   .map { |address| address.strip.downcase }
                                                   .compact_blank
      end

      def self.active?
        addresses.any?
      end

      def self.allowed?(user)
        !active? || addresses.include?(user&.email.to_s.downcase)
      end

      def self.time_tracker_event?(event_class_name)
        event_class_name.to_s.start_with?(EVENT_PREFIX)
      end

      # Prepended to Decidim::NotificationMailer: a Time Tracker event for
      # someone off the list renders no message, so nothing is delivered.
      module NotificationMailerGuard
        def event_received(event, event_class_name, resource, user, user_role, extra) # rubocop:disable Metrics/ParameterLists
          return if EmailAllowlist.time_tracker_event?(event_class_name) && !EmailAllowlist.allowed?(user)

          super
        end
      end

      # Prepended to Decidim::NotificationsDigestMailer: drops Time Tracker
      # notifications from the digest of someone off the list. A digest left
      # empty is not sent (core before 0.31.7 would send it with no items).
      module DigestMailerGuard
        def digest_mail(user, notification_ids)
          unless EmailAllowlist.allowed?(user)
            notification_ids = Decidim::Notification.where(id: notification_ids)
                                                    .where.not("event_class LIKE ?", "#{EVENT_PREFIX}%")
                                                    .pluck(:id)
            return if notification_ids.empty?
          end

          super
        end
      end
    end
  end
end
