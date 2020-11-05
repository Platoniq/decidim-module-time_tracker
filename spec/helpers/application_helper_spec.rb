# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    describe Decidim::TimeTracker::ApplicationHelper do
      describe "clockify_seconds" do
        it "renders the time as hours, minutes and seconds" do
          expect(helper.clockify_seconds(1337)).to match(
            "<span class=\"time-tracker--clock\">" \
              "<span class=\"text-muted\">0h</span>" \
              "<span>22m</span>" \
              "<span>17s</span>" \
            "</span>"
          )
        end

        it "renders hours, minutes and seconds with \"text-muted\" class when their value is zero" do
          expect(helper.clockify_seconds(0)).to match(
            "<span class=\"time-tracker--clock\">" \
              "<span class=\"text-muted\">0h</span>" \
              "<span class=\"text-muted\">0m</span>" \
              "<span class=\"text-muted\">0s</span>" \
            "</span>"
          )
        end

        context "when :padded" do
          it "renders the time as hours, minutes and seconds with two digits" do
            expect(helper.clockify_seconds(2, padded: true)).to match(
              "<span class=\"time-tracker--clock\">" \
                "<span class=\"text-muted\">00h</span>" \
                "<span class=\"text-muted\">00m</span>" \
                "<span>02s</span>" \
              "</span>"
            )
          end
        end
      end
    end
  end
end
