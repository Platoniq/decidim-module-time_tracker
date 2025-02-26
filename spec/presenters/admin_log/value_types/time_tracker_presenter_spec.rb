# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe AdminLog::ValueTypes::TimeTrackerPresenter do
    include Decidim::TranslatableAttributes

    subject { described_class.new(time_tracker_id, self) }

    let(:time_tracker) { create(:time_tracker) }
    let(:time_tracker_id) { time_tracker.id }

    describe "#present" do
      it "handles i18n fields" do
        expect(subject.present).to eq time_tracker.component.name["en"]
      end

      context "when no value found" do
        let(:time_tracker_id) { 1234 }

        it "returns not found" do
          expect(subject.present).to include "not found"
          expect(subject.present).to include "ID: #{time_tracker_id}"
        end
      end
    end
  end
end
