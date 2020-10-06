# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe MilestoneForm do
    subject(:form) { described_class.from_params(attributes) }

    let(:activity) { create :activity }
    let(:title) { "My milestone" }
    let(:attachment_params) { nil }
    let(:attributes) do
      {
        activity_id: activity.id,
        title: title,
        attachment: attachment_params
      }
    end

    it { is_expected.to be_valid }

    describe "when title is missing" do
      let(:title) { nil }

      it { is_expected.not_to be_valid }
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

        it "adds an error to the `:attachment` field" do
          expect(subject).not_to be_valid

          expect(subject.errors.full_messages).to match_array(["Attachment Needs to be reattached", "What have you done? can't be blank"])
          expect(subject.errors.keys).to match_array([:title, :attachment])
        end
      end
    end
  end
end
