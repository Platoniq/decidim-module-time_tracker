# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe MilestoneCell, type: :cell do
    controller Decidim::TimeTracker::MilestonesController

    subject { cell("decidim/time_tracker/milestone", model, options).call }

    let(:model) { create(:milestone) }
    let(:options) { {} }

    it "renders the cell" do
      expect(subject).to have_css(".card--milestone")
    end

    context "when the cell is called with no options" do
      it "shows the milestone title as card title" do
        within ".card__header" do
          expect(subject).to have_text(model.title)
        end
      end

      it "doesn't link to the user milestones" do
        within ".card__header" do
          expect(subject).not_to have_link(milestones_path(user_id: user.id))
        end
      end

      it "shows the milestone created_at date in the footer" do
        within ".card__footer" do
          expect(subject).to have_text(model.created_at.strftime("%H:%M"))
          expect(subject).to have_text(model.created_at.strftime("%d %b %Y"))
        end
      end
    end

    context "when the cell is called with `type: :list` in options" do
      let(:options) { { type: :list } }

      it "shows the user title as card title" do
        within ".card__header" do
          expect(subject).to have_text(user.name)
        end
      end

      it "links to the user milestones" do
        within ".card__header" do
          expect(subject).to have_link(milestones_path(user_id: user.id))
        end
      end

      it "shows the elapsed time for the user in the footer" do
        within ".card__footer" do
          expect(subject).to have_text(model.activity.user_seconds_elapsed(model.user))
        end
      end
    end

    context "when the model doesn't have an image" do
      it "uses the generic icon" do
        expect(subject).to have_css(".icon--timer")
      end
    end

    context "when the model has an image", processing_uploads_for: Decidim::AttachmentUploader do
      let!(:image) { create(:attachment, attached_to: model) }

      it "uses that image" do
        expect(subject.to_s).to include(model.attachments.first.url)
      end
    end
  end
end
