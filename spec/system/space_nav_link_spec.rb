# frozen_string_literal: true

require "spec_helper"

describe "Skills and badges link in a space's navigation" do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :published, organization:) }

  before do
    create(:content_block, organization:, scope_name: :participatory_process_homepage, manifest_name: :main_data,
                           scoped_resource_id: participatory_process.id)
    switch_to_host(organization.host)
  end

  context "when the space has a published Time Tracker" do
    before do
      create(:time_tracker_component, :published, participatory_space: participatory_process)
      visit decidim_participatory_processes.participatory_process_path(participatory_process)
    end

    it "links to the explainer from the landing page and the space dropdown" do
      within "#dropdown-menu-participatory-space" do
        expect(page).to have_link("How skills and badges work", href: "/badges")
      end
      expect(page).to have_css("[id^='breadcrumb-secondary-dropdown'] a[href='/badges']", visible: :all)
    end
  end

  context "when the space has no Time Tracker" do
    before do
      create(:component, :published, manifest_name: "pages", participatory_space: participatory_process)
      visit decidim_participatory_processes.participatory_process_path(participatory_process)
    end

    it "does not show the link" do
      expect(page).to have_no_link(href: "/badges", visible: :all)
    end
  end
end
