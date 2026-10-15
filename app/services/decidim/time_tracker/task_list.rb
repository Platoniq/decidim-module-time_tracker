# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Everything the public pages of a time tracker show — its tasks, their
    # active activities, who works on each one, the visitor's own requests and
    # the latest milestones — loaded in a fixed number of queries.
    #
    # The page used to ask each activity for all of this in turn, which came
    # to several hundred queries for a programme of a few dozen activities.
    class TaskList
      def initialize(time_tracker, user = nil)
        @time_tracker = time_tracker
        @user = user
      end

      # Tasks with at least one active activity, in the order admins set.
      def tasks
        @tasks ||= all_tasks.select { |task| activities_for(task).any? }
      end

      def activities_for(task)
        @activities_for ||= {}
        @activities_for[task.id] ||= task.activities.select(&:active?)
      end

      def activities
        @activities ||= tasks.flat_map { |task| activities_for(task) }
      end

      delegate :empty?, to: :activities

      # The visitor's own request for an activity, whatever its status.
      def assignation_for(activity)
        user_assignations[activity.id]
      end

      # The activities the visitor has been accepted onto: the ones they can
      # track time on.
      def accepted_activities
        @accepted_activities ||= activities.select { |activity| assignation_for(activity)&.accepted? }
      end

      # People accepted onto an activity, the visitor included.
      def participants_for(activity)
        participants_by_activity.fetch(activity.id, [])
      end

      def volunteers_count(task = nil)
        scope = task ? activities_for(task) : activities
        scope.flat_map { |activity| participants_for(activity) }.uniq.size
      end

      # Each participant's latest milestone on the activity, newest first.
      def milestones_for(activity)
        milestones_by_activity.fetch(activity.id, [])
      end

      # The span of a task's activities, for "1 Aug – 1 Dec".
      def date_range_for(task)
        starts = activities_for(task).filter_map(&:start_date)
        ends = activities_for(task).filter_map(&:end_date)
        [starts.min, ends.max]
      end

      # The average progress of the tasks that report one, as a whole
      # percentage; nil when none does, so the page can leave the bar out.
      def global_progress
        return @global_progress if defined?(@global_progress)

        values = all_tasks.filter_map(&:progress)
        @global_progress = values.empty? ? nil : (values.sum.to_f / values.size).round
      end

      # Time tracked by everyone, across every activity on the page.
      def tracked_seconds
        @tracked_seconds ||= TimeEvent.unscope(:order).where(activity_id: activity_ids).sum(:total_seconds)
      end

      private

      attr_reader :time_tracker, :user

      def all_tasks
        @all_tasks ||= time_tracker.tasks.includes(:skills, activities: { image_attachment: :blob }).to_a
      end

      def activity_ids
        activities.map(&:id)
      end

      def user_assignations
        @user_assignations ||= if user
                                 Assignation.where(user:, activity_id: activity_ids).index_by(&:activity_id)
                               else
                                 {}
                               end
      end

      def participants_by_activity
        @participants_by_activity ||= Assignation.accepted
                                                 .where(activity_id: activity_ids)
                                                 .includes(:user)
                                                 .order(:id)
                                                 .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |assignation, grouped|
          participant = assignation.user
          grouped[assignation.activity_id] << participant if participant && !participant.deleted? && !participant.blocked?
        end
      end

      def milestones_by_activity
        @milestones_by_activity ||= Milestone.where(activity_id: activity_ids)
                                             .select("DISTINCT ON (activity_id, decidim_user_id) *")
                                             .order(:activity_id, :decidim_user_id, created_at: :desc)
                                             .includes(:user, attachments: { file_attachment: :blob })
                                             .group_by(&:activity_id)
                                             .transform_values { |milestones| milestones.sort_by(&:created_at).reverse }
      end
    end
  end
end
