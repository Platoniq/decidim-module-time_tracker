# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class TimeTrackerExportsController < Admin::ApplicationController
        def export
          # enforce_permission_to :import, :time_tracker

          ExportTimeTracker.call(current_component, current_user) do
            on(:ok) do |accountability_component|
              flash[:notice] = I18n.t("time_tracker_exports.create.success", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(accountability_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("time_tracker_exports.create.error", scope: "decidim.time_tracker.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
