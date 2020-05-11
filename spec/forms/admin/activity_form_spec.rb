# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Admin::ActivityForm do
    subject(:form) { described_class.from_params(attributes).with_context(context) }

    let(:organization) { create(:organization, available_locales: [:en]) }
    let(:context) do
      {
        current_organization: organization,
        current_component: current_component,
        current_participatory_space: participatory_process
      }
    end
    let(:participatory_process) { create :participatory_process, organization: organization }
    let(:current_component) { create :time_tracker_component, participatory_space: participatory_process }

    let(:description) do
      Decidim::Faker::Localized.sentence(3)
    end
    let(:start_date) { 2.days.from_now.strftime "%d/%m/%Y" }
    let(:end_date) { (2.days.from_now + 1.day).strftime "%d/%m/%Y" }
    let(:requests_start_at) { 3.days.from_now }

    let(:attributes) do
      {
        description: description,
        active: true,
        start_date: start_date,
        end_date: end_date,
        max_minutes_per_day: 3600,
        requests_start_at: requests_start_at
      }
    end

    it { is_expected.to be_valid }

    # TODO: validate end_date after start_date if not empty
  end
end
