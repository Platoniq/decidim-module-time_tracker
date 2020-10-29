# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update activity from Decidim's admin panel
      class ActivityForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :description, String

        attribute :active, Boolean
        attribute :start_date, Decidim::Attributes::LocalizedDate
        attribute :end_date, Decidim::Attributes::LocalizedDate
        attribute :max_minutes_per_day, Integer
        attribute :requests_start_at, Decidim::Attributes::TimeWithZone

        validates :start_date, presence: true
        validates :end_date, presence: true, date: { after: :start_date }
        validates :requests_start_at, presence: true, date: { before: :start_date }

        validates :max_minutes_per_day, presence: true
        validates :description, translatable_presence: true
      end
    end
  end
end
