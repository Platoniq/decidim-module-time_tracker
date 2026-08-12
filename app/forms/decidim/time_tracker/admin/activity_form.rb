# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update activity from Decidim's admin panel
      class ActivityForm < Decidim::Form
        include TranslatableAttributes
        include Decidim::HasUploadValidations

        translatable_attribute :description, String

        attribute :progress, Decimal

        attribute :active, Boolean
        attribute :start_date, Decidim::Attributes::TimeWithZone
        attribute :end_date, Decidim::Attributes::TimeWithZone
        attribute :max_minutes_per_day, Integer
        attribute :requests_start_at, Decidim::Attributes::TimeWithZone
        attribute :min_events, Integer, default: 0
        attribute :min_duration_minutes_per_event, Integer, default: 0

        attribute :image
        attribute :remove_image, Boolean, default: false

        validates :image, passthru: { to: Decidim::TimeTracker::Activity }

        validates :start_date, presence: true
        validates :end_date, presence: true, date: { after: :start_date }
        validates :requests_start_at, presence: true, date: { before: :start_date }

        validates :max_minutes_per_day, presence: true
        validates :min_events, numericality: { greater_than_or_equal_to: 0 }
        validates :min_duration_minutes_per_event, numericality: { greater_than_or_equal_to: 0 }
        validates :description, translatable_presence: true
      end
    end
  end
end
