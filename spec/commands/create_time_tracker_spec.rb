# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TimeTracker
    module Admin
      describe CreateTimeTracker do
        describe "call" do
          let(:component) { create(:component, manifest_name: "time_tracker") }
          let(:command) { described_class.new(component) }

          describe "when the time tracker is not saved" do
            before do
              # rubocop:disable RSpec/AnyInstance
              expect_any_instance_of(Decidim::TimeTracker::TimeTracker).to receive(:save).and_return(false)
              # rubocop:enable RSpec/AnyInstance
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create a time tracker" do
              expect do
                command.call
              end.not_to change(Decidim::TimeTracker::TimeTracker, :count)
            end
          end

          describe "when the time tracker is saved" do
            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates a new time tracker with the same name as the component" do
              expect(Decidim::TimeTracker::TimeTracker).to receive(:new).with(component: component).and_call_original

              expect do
                command.call
              end.to change(Decidim::TimeTracker::TimeTracker, :count).by(1)
            end
          end
        end
      end
    end
  end
end
