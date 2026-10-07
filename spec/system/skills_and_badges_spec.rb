# frozen_string_literal: true

require "spec_helper"

describe "Telling skills and badges apart" do
  include_context "with a time_tracker"

  let(:task) { create(:task, time_tracker:, name: { en: "Trust-building workshops" }) }
  let!(:activity) { create(:activity, task:) }
  let!(:skill) { create(:skill, organization:, name: { en: "Group facilitation" }, tasks: [task]) }
  let!(:badge) { create(:time_tracker_badge, organization:, name: { en: "Workshop regular" }, levels: [1, 3, 5], tasks: [task]) }

  before do
    switch_to_host(organization.host)
  end

  it "sets them side by side on the public page" do
    visit decidim.public_badges_path

    within ".time-tracker-compare" do
      expect(page).to have_content("Skill or badge?")
      expect(page).to have_content("What you can do")
      expect(page).to have_content("How much you have done")
    end
    within(".time-tracker--skill") { expect(page).to have_content("Group facilitation") }
    within(".time-tracker--badge") { expect(page).to have_content("Workshop regular") }
  end

  it "labels each reward of a task with its kind" do
    visit Decidim::EngineRouter.main_proxy(component).root_path

    within ".time-tracker__earnings" do
      expect(page).to have_css(".time-tracker__earning", text: /skill\s+Group facilitation/i)
      expect(page).to have_css(".time-tracker__earning", text: /badge\s+Workshop regular\s+Levels at 1 → 3 → 5 verified activity completions/i)
    end
  end
end
