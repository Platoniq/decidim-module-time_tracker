# frozen_string_literal: true

module Decidim
  module TimeTracker
    class Permissions < Decidim::DefaultPermissions
      def permissions
        # for the moment, we let public views for milestones
        allow! if permission_action.subject == :milestone && permission_action.action == :show

        return permission_action unless user

        return Decidim::TimeTracker::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin

        case permission_action.subject
        when :questionnaire
          allow_answer?
        when :assignation
          allow_assignation?
        when :milestone
          allow_milestone?
        else
          allow!
        end

        permission_action
      end

      def allow_answer?
        return false unless permission_action.action == :answer

        allow! if current_component&.published?
      end

      def allow_assignation?
        return allow! unless activity

        if permission_action.action == :create
          return false if activity.has_assignation? user

          return false unless activity.status.in? [:open, :not_started]

          allow!
        end
      end

      def allow_milestone?
        return false unless activity

        if permission_action.action == :create
          return false unless activity.assignation_accepted? user

          return false if activity.status.in? [:inactive]

          allow!
        end
      end

      private

      def activity
        @activity ||= context.fetch(:activity, nil)
      end

      def current_component
        @current_component ||= context.fetch(:current_component, nil)
      end
    end
  end
end
