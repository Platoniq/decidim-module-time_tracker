# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe MilestoneForm do
    subject(:form) { described_class.from_params(attributes).with_context(context) }

    let(:organization) { create(:organization) }
    let(:context) { { current_organization: organization } }
    let(:activity) { create(:activity) }
    let(:title) { "My milestone" }
    let(:description) { "Description" }
    let(:attachment_params) { nil }
    let(:attributes) do
      {
        activity_id: activity.id,
        title:,
        description:,
        attachment: attachment_params
      }
    end

    it { is_expected.to be_valid }

    describe "when title is missing" do
      let(:title) { nil }

      it { is_expected.not_to be_valid }
    end

    describe "when description is missing" do
      let(:description) { nil }

      it { is_expected.to be_valid }
    end

    context "when the attachment is present" do
      let(:attachment_params) do
        {
          title: "My attachment",
          file: Decidim::Dev.test_file("city.jpeg", "image/jpeg")
        }
      end

      it { is_expected.to be_valid }

      context "when the form has some errors" do
        let(:title) { nil }

        it "adds an error" do
          expect(subject).not_to be_valid

          expect(subject.errors.full_messages).to contain_exactly("What have you done? cannot be blank")
          expect(subject.errors.attribute_names).to contain_exactly(:title)
        end
      end
    end
  end
end
