# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Milestone do
      subject { milestone }

      let(:milestone) { create(:milestone, time_tracker: time_tracker, time_entries: time_entries, user: user) }
      let(:time_tracker) { create(:time_tracker) }
      let(:time_entries) { create_list(:time_entry, 3) }
      let(:user) { create(:user) }

      context "when the milestone is correctly associated" do
        it "belongs to a time tracker" do
          expect(subject.time_tracker.id).to eq(time_tracker.id)
        end

        it "has many time_entries" do
          expect(subject.time_entries.count).to eq 3
          expect(subject.time_entries.first.id).to eq(time_entries.first.id)
          expect(subject.time_entries.second.id).to eq(time_entries.second.id)
          expect(subject.time_entries.third.id).to eq(time_entries.third.id)
        end

        it "has a user" do
          expect(subject.user.id).to eq(user.id)
        end
      end

      context "when it has attachments", processing_uploads_for: Decidim::AttachmentUploader do
        let!(:image) { create(:attachment, attached_to: milestone) }

        it "finds the image" do
          expect(milestone.attachments.first.id).to eq(image.id)
        end
      end
    end
  end
end
