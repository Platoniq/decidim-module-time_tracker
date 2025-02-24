# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe MilestoneCell, type: :cell do
    controller Decidim::TimeTracker::MilestonesController

    subject { my_cell.call }

    let(:my_cell) { cell("decidim/time_tracker/milestone", model, type:) }
    let(:model) { create(:milestone) }
    let(:type) { nil }
    # For some reason "within" does not work well in cells, so using "find"
    let(:card_info) { subject.find(".card__grid-text") }
    let(:card_link) { subject.find(".card__link") }

    it "renders the cell" do
      expect(subject).to have_css(".milestone-card")
    end

    it "has common classes" do
      expect(subject).to have_css(".card__grid-img")
      expect(subject).to have_css(".card__grid-text")
    end

    context "when the cell is called with no options" do
      it "shows the milestone title as card title" do
        expect(card_info).to have_text(model.title)
      end

      it "doesn't link to the user milestones" do
        expect(card_info).to have_no_link(my_cell.milestones_path)
      end

      it "shows the milestone created_at date in the footer" do
        expect(card_info).to have_text(model.created_at.strftime("%H:%M"))
        expect(card_info).to have_text(model.created_at.strftime("%d %b %Y"))
      end
    end

    context "when the cell is called with `type: :list` in options" do
      let(:type) { :list }

      it "shows the user title as card title" do
        expect(card_info).to have_css("b")
        expect(card_info).to have_text(model.user.name)
        expect(card_info).to have_text("activity")
      end

      it "links to the user milestones" do
        expect(card_info).to have_link(href: my_cell.milestones_path)
      end

      it "shows the elapsed time for the user in the footer" do
        expect(card_info).to have_text(model.activity.user_seconds_elapsed(model.user))
      end
    end

    context "when the model doesn't have an image" do
      it "uses the generic icon" do
        expect(subject).to have_css(".empty")
      end
    end

    context "when the model has an image", processing_uploads_for: Decidim::AttachmentUploader do
      let!(:image) { create(:attachment, attached_to: model) }

      it "uses that image" do
        expect(subject.to_s).to include(model.attachments.first.url)
      end

      it "links to the user milestones" do
        expect(subject).to have_css(".card__link")
        expect(card_link).to have_css(".card__image")
        expect(card_link[:href]).to eq(my_cell.milestones_path)
      end
    end
  end
end
