# frozen_string_literal: true

require "spec_helper"

describe "Badges tab of a participant's profile" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:participatory_space) { create(:participatory_process, organization:) }
  let(:component) { create(:time_tracker_component, participatory_space:) }
  let(:time_tracker) { create(:time_tracker, component:) }
  let(:task) { create(:task, time_tracker:, name: { en: "Trust-building workshops" }) }
  let(:skill) { create(:skill, organization:, name: { en: "Group facilitation" }) }

  before do
    switch_to_host(organization.host)
  end

  context "when the participant has earned time tracker skills and badges" do
    let!(:badge) do
      create(:time_tracker_badge, organization:, metric: "skills_earned", levels: [1, 3],
                                  name: { en: "Skill collector" }, description: { en: "Skills certified anywhere." })
    end

    before do
      create(:skill_certification, user:, task:, skill:, earned_at: Time.zone.local(2026, 10, 1))
      visit decidim.profile_badges_path(nickname: user.nickname)
    end

    it "leads with the skills and badges they earned" do
      expect(page).to have_content("Skills and badges")

      within "[data-skill='#{skill.id}']" do
        expect(page).to have_content("Group facilitation")
        expect(page).to have_content("Trust-building workshops")
      end

      within "[data-time-tracker-badge='#{badge.id}']" do
        expect(page).to have_content("Skill collector")
        expect(page).to have_content("Level 1 of 2")
        expect(page).to have_content("Skills certified anywhere.")
      end
    end

    it "leaves out the generic badges they have not earned" do
      expect(page).to have_no_content(I18n.t("decidim.gamification.title"))
      expect(page).to have_no_css("[data-badge='followers']")
    end
  end

  context "when the participant has no time tracker achievements" do
    before do
      visit decidim.profile_badges_path(nickname: user.nickname)
    end

    it "shows Decidim's badges as before" do
      expect(page).to have_content(I18n.t("decidim.gamification.title"))
      expect(page).to have_css("[data-badge='followers']")
      expect(page).to have_no_content("Skills and badges")
    end
  end
end
