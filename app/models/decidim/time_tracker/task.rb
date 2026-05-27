# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for a Task in the Decidim::TimeTracker component.
    class Task < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = :decidim_time_tracker_tasks

      belongs_to :time_tracker,
                 class_name: "Decidim::TimeTracker::TimeTracker"

      has_many :activities,
               -> { order("decidim_time_tracker_activities.weight" => :asc, "decidim_time_tracker_activities.id" => :asc) },
               class_name: "Decidim::TimeTracker::Activity",
               dependent: :destroy

      scope :active, -> { where(active: true) }

      delegate :questionnaire, to: :time_tracker
      delegate :component, to: :time_tracker

      validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

      def progress
        p = super if self.class.column_names.include?("progress")
        return p if p.present?

        progress_from_text || progress_from_activities
      end

      def starts_at
        activities.order(start_date: :asc).first&.start_date
      end

      def ends_at
        activities.order(end_date: :desc).first&.end_date
      end

      def assignations_count(filter: :accepted)
        assignations = Assignation.where(activity: activities).send(filter)
        assignations.count
      end

      def user_is_assignation?(user, filter: :accepted)
        Assignation.where(user:, activity: activities).send(filter).any?
      end

      def self.log_presenter_class_for(_log)
        Decidim::TimeTracker::AdminLog::TaskPresenter
      end

      def self.ransackable_attributes(_auth_object = nil)
        %w(id name)
      end

      def self.ransackable_associations(_auth_object = nil)
        %w(activity time_tracker)
      end

      private

      def progress_from_text
        return nil if name.blank?

        texts = name.is_a?(Hash) ? name.values : [name]
        texts.each do |text|
          match = text.to_s.match(/\((\d+)%\)/)
          return match[1].to_i if match
        end
        nil
      end

      def progress_from_activities
        active_activities = activities.active
        return nil if active_activities.empty?

        valid_progresses = active_activities.map(&:progress).compact
        return nil if valid_progresses.empty?

        (valid_progresses.sum.to_f / valid_progresses.size).round(2)
      end
    end
  end
end
