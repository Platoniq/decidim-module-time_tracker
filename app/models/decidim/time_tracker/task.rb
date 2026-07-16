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

      has_many :skill_certifications,
               class_name: "Decidim::TimeTracker::SkillCertification",
               foreign_key: "decidim_time_tracker_task_id",
               dependent: :destroy

      has_many :task_skills,
               class_name: "Decidim::TimeTracker::TaskSkill",
               foreign_key: "decidim_time_tracker_task_id",
               inverse_of: :task,
               dependent: :destroy

      has_many :skills,
               through: :task_skills,
               class_name: "Decidim::TimeTracker::Skill"

      has_many :badge_tasks,
               class_name: "Decidim::TimeTracker::BadgeTask",
               foreign_key: "decidim_time_tracker_task_id",
               inverse_of: :task,
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
        # reorder (not order) so the association's default weight/id ordering
        # doesn't take precedence over the date sort.
        activities.reorder(start_date: :asc).first&.start_date
      end

      def ends_at
        activities.reorder(end_date: :desc).first&.end_date
      end

      def assignations_count(filter: :accepted)
        assignations = Assignation.where(activity: activities).send(filter)
        assignations.count
      end

      def user_is_assignation?(user, filter: :accepted)
        Assignation.where(user:, activity: activities).send(filter).any?
      end

      # Whether the given user has completed this task, i.e. every active
      # activity of the task has at least `required_completions` admin-verified
      # completions for that user. A task with no active activities is never
      # considered completed.
      def completed_by?(user, required_completions: 1)
        active_activities = activities.active
        return false if active_activities.empty?

        verified_counts = ActivityCompletion.verified
                                            .joins(:assignation)
                                            .where(decidim_time_tracker_assignations: { decidim_user_id: user.id, activity_id: active_activities.ids })
                                            .group("decidim_time_tracker_assignations.activity_id")
                                            .count

        active_activities.ids.all? { |activity_id| verified_counts.fetch(activity_id, 0) >= required_completions }
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
