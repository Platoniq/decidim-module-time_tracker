# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe Admin::AssignationForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:name) { "Lord of the Foo" }
    let(:email) { "depths@ofthe.bar" }

    let(:attributes) do
      {
        name:,
        email:
      }
    end

    it { is_expected.to be_valid }

    context "when user exists" do
      subject(:form) { described_class.from_model(assignation).with_context(context) }

      let(:assignation) { create(:assignation) }
      let(:context) do
        {
          current_organization: assignation.user.organization
        }
      end

      it { is_expected.to be_valid }

      it "user exists" do
        expect(subject.existing_user).to be(true)
      end
    end
  end
end
