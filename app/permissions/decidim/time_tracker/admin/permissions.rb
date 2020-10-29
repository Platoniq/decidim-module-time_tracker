# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin

          allowed_task_action?
          allowed_assignee_action?

          permission_action
        end

        def allowed_task_action?
          return unless permission_action.subject == :task

          case permission_action.action
          when :create, :update, :destroy
            permission_action.allow!
          end
        end

        def allowed_assignee_action?
          return unless permission_action.subject == :assignee
          
          if permission_action.action == :update
            return permission_action.allow! if assignee.can_change_status?
          end

          case permission_action.action
          when :create, :destroy
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
