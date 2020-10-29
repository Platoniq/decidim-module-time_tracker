# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin

          allowed_task_action?
          allowed_activity_action?
          allowed_assignee_action?

          permission_action
        end

        def allowed_task_action?
          return unless permission_action.subject.in? [:task, :tasks]

          case permission_action.action
          when :index, :create, :update, :destroy
            permission_action.allow!
          end
        end

        def allowed_activity_action?
          return unless permission_action.subject.in? [:activity, :activities]

          case permission_action.action
          when :index, :create, :update, :destroy
            permission_action.allow!
          end
        end

        def allowed_assignee_action?
          return unless permission_action.subject.in? [:assignee, :assignees]

          case permission_action.action
          when :update
            permission_action.allow! if assignee.can_change_status?
          when :index, :create, :destroy
            permission_action.allow!
          end
        end

        def assignee
          @assignee ||= context.fetch(:assignee, nil)
        end
      end
    end
  end
end
