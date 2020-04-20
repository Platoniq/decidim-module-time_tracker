# frozen_string_literal: true

module Decidim
  module TimeTracker
    class ActivitiesController < Decidim::TimeTracker::ApplicationController
      helper_method :task, :activities

      private

      def task
        Task.find(params[:task_id])
      end

      def activities
        Activity.where(task: task)
      end
    end
  end
end
