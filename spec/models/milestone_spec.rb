# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Milestone do
      subject { milestone }

      let(:milestone) { create(:milestone, component: component, user: user) }
      let(:component) { create(:time_tracker_component) }
      let(:user) { create(:user) }

      context "when the milestone is correctly associated" do
        it "belongs to a component" do
          expect(subject.component.id).to eq(component.id)
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
