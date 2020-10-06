# frozen_string_literal: true

module Decidim
  module TimeTracker
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        allow!

        permission_action
      end
    end
  end
end
