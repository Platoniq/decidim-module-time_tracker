# frozen_string_literal: true

module Decidim
  module TimeTracker
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        return Decidim::TimeTracker::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin

        allow!

        permission_action
      end
    end
  end
end
