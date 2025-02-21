# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe AdminLog::ValueTypes::ActivityPresenter do
    include Decidim::TranslatableAttributes

    subject { described_class.new(activity_id, self) }

    let(:activity) { create(:activity, description:) }
    let(:activity_id) { activity.id }
    let(:description) do
      {
        "en" => "My value",
        "es" => "My title in Spanish"
      }
    end

    describe "#present" do
      it "handles i18n fields" do
        expect(subject.present).to eq "My value"
      end

      context "when no value found" do
        let(:activity_id) { 1234 }

        it "returns not found" do
          expect(subject.present).to include "not found"
          expect(subject.present).to include "ID: #{activity_id}"
        end
      end
    end
  end
end
