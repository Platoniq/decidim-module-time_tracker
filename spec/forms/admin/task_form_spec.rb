# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Admin::TaskForm do
    subject(:form) { described_class.from_params(attributes).with_context(context) }

    let(:organization) { create(:organization, available_locales: [:en]) }
    let(:context) do
      {
        current_organization: organization,
        current_component:,
        current_participatory_space: participatory_process
      }
    end
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:current_component) { create(:time_tracker_component, participatory_space: participatory_process) }

    let(:name) do
      Decidim::Faker::Localized.sentence(word_count: 3)
    end

    let(:attributes) do
      {
        name:
      }
    end

    it { is_expected.to be_valid }
  end
end
