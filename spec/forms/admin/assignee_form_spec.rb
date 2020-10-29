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

    context "when user exists" do
      subject(:form) { described_class.from_model(assignee).with_context(context) }

      let(:assignee) { create :assignee }
      let(:context) do
        {
          current_organization: assignee.user.organization
        }
      end

      it { is_expected.to be_valid }

      it "user exists" do
        expect(subject.existing_user).to eq(true)
      end
    end
  end
end
