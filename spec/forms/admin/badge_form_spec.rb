# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  module Admin
    describe BadgeForm do
      subject { described_class.from_params(attributes).with_context(context) }

      let(:organization) { create(:organization) }
      let(:context) { { current_organization: organization } }
      let(:metric) { "completed_activities" }
      let(:levels_count) { 3 }
      let(:level_thresholds) { %w(1 3 5) }

      let(:attributes) do
        {
          badge: {
            name: { en: "Volunteer" },
            description: { en: "For turning up." },
            metric:,
            levels_count:,
            level_thresholds:,
            weight: 0,
            active: true
          }
        }
      end

      it { is_expected.to be_valid }

      describe "#levels" do
        it "keeps as many thresholds as the chosen level count" do
          expect(subject.levels).to eq([1, 3, 5])
        end

        it "ignores thresholds beyond the chosen level count" do
          subject.levels_count = 2

          expect(subject.levels).to eq([1, 3])
        end

        context "when the admin only picks a level count" do
          let(:level_thresholds) { [] }

          it "fills in the metric's default curve" do
            expect(subject.levels).to eq(Decidim::TimeTracker::Badge.default_levels("completed_activities", 3))
          end
        end

        context "when the admin leaves one level blank" do
          let(:level_thresholds) { ["2", "", "9"] }

          it "fills only the blank level from the defaults" do
            expect(subject.levels).to eq([2, 3, 9])
          end
        end

        context "with the hours metric" do
          let(:metric) { "time_dedicated_hours" }
          let(:level_thresholds) { [] }

          it "uses a curve suited to hours" do
            expect(subject.levels).to eq([1, 5, 10])
          end
        end
      end

      it "is invalid when the thresholds do not ascend" do
        subject.level_thresholds = [5, 3, 1]

        expect(subject).not_to be_valid
      end

      it "is invalid when a threshold is zero" do
        subject.level_thresholds = [0, 3, 5]

        expect(subject).not_to be_valid
      end

      it "is invalid with more levels than are supported" do
        subject.levels_count = Decidim::TimeTracker::Badge::MAX_LEVELS + 1

        expect(subject).not_to be_valid
      end

      it "is invalid without a level" do
        subject.levels_count = 0

        expect(subject).not_to be_valid
      end

      context "with the required_skills metric" do
        let(:metric) { "required_skills" }

        it "is invalid without skills" do
          expect(subject).not_to be_valid
        end
      end
    end
  end
end
