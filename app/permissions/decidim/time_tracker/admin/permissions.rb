# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin

          permission_action.allow! if permission_action.action.in? [:update, :destroy]

          allowed_task_action?

          permission_action
        end

        def allowed_task_action?
          return unless permission_action.subject == :task

          case permission_action.action
          when :create, :update, :destroy
            permission_action.allow!
          end
        end
      end
    end
  end
end
