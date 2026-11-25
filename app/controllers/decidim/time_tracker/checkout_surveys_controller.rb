# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Receives the check-out survey sent after a volunteer stops a timer.
    class CheckoutSurveysController < Decidim::TimeTracker::ApplicationController
      include Decidim::FormFactory

      def create
        enforce_permission_to :create, :checkout_survey
        return head :not_found unless component_settings.checkout_survey_enabled

        form = form(CheckoutSurveyForm).from_params(params)
        SubmitCheckoutSurvey.call(form, activity:, user: current_user, donation_enabled: component_settings.data_donation_enabled) do
          on(:ok) do
            render json: { message: I18n.t("checkout_surveys.create.success", scope: "decidim.time_tracker"),
                           dataAnswered: DataDonation.answered_by?(current_user) }
          end
          on(:invalid) do
            render json: { message: I18n.t("checkout_surveys.create.error", scope: "decidim.time_tracker") }, status: :unprocessable_entity
          end
        end
      end

      private

      def activity
        @activity ||= time_tracker.activities.find(params[:activity_id])
      end
    end
  end
end
