# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Lets volunteers withdraw the demographic data they donated, from their
    # "My voluntary work" page. Withdrawing deletes it.
    class DataDonationsController < Decidim::ApplicationController
      # Only touches the current user's own donation
      def destroy # rubocop:disable Decidim/EnforcePermissionTo
        return redirect_to decidim.new_user_session_path unless current_user

        DataDonation.where(user: current_user).delete_all # rubocop:disable Decidim/OrganizationScopedFinder
        flash[:notice] = I18n.t("data_donations.destroy.success", scope: "decidim.time_tracker")
        redirect_to decidim.my_voluntary_work_path
      end
    end
  end
end
