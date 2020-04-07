# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Admin::AssigneeForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:name) { "Lord of the Foo" }
    let(:email) { "depths@ofthe.bar" }

    let(:attributes) do
      {
        name: name,
        email: email
      }
    end

    it { is_expected.to be_valid }
  end
end
