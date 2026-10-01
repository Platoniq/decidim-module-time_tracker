# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Notifies a user that their work on a task has certified them in a skill.
    #
    # The resource is the task, because that is where the work happened. The
    # skill travels in `extra`: a task with explicit skills certifies those
    # skills, and only a task without any certifies itself under its own name.
    class SkillCertifiedEvent < Decidim::Events::SimpleEvent
      i18n_attributes :task_title

      def resource_url
        router.user_report_url
      end

      def resource_path
        router.user_report_path
      end

      def task
        @task ||= resource
      end

      def skill
        return @skill if defined?(@skill)

        @skill = Decidim::TimeTracker::Skill.find_by(id: extra[:skill_id]) if extra[:skill_id].present?
      end

      def resource_title
        decidim_sanitize_translated(skill ? skill.name : task.name)
      end

      def task_title
        decidim_sanitize_translated(task.name)
      end

      private

      # The engine is mounted once per component, so routes must be resolved
      # through the component's router or they lack the mount prefix.
      def router
        @router ||= Decidim::EngineRouter.main_proxy(task.component)
      end
    end
  end
end
