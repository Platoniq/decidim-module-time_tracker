# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Every participatory space with a published Time Tracker links to the
    # public "How skills and badges work" page (/badges) from its own
    # navigation: the dropdown under the space's breadcrumb and the component
    # buttons on its landing page. Skills and badges are earned through the
    # component but follow rules that span the platform, so the explainer is
    # one click away wherever the space is browsed, not only inside the
    # component.
    module SpaceNavLink
      ITEM_ID = "time-tracker-skills-badges"

      # The cells whose nav_items list a space's components. The dropdown
      # cell is the base class of every space type's dropdown; the landing
      # page's main data block is defined per space type.
      CELLS = %w(
        Decidim::ParticipatorySpaceDropdownMetadataCell
        Decidim::ParticipatoryProcesses::ContentBlocks::MainDataCell
        Decidim::Assemblies::ContentBlocks::MainDataCell
        Decidim::Conferences::ContentBlocks::MainDataCell
      ).freeze

      def self.install!
        CELLS.each { |name| name.safe_constantize&.prepend(NavItems) }
      end

      def self.item_for(space)
        return unless space.respond_to?(:components)
        return unless space.components.published.exists?(manifest_name: "time_tracker")

        {
          id: ITEM_ID,
          # Falls back to English in locales that lack the label.
          name: I18n.t("decidim.time_tracker.badges.how_it_works",
                       default: I18n.t("decidim.time_tracker.badges.how_it_works", locale: :en)),
          url: Decidim::Core::Engine.routes.url_helpers.public_badges_path,
          active: false
        }
      end

      module NavItems
        private

        def nav_items
          items = super
          space = respond_to?(:resource, true) ? resource : model
          item = SpaceNavLink.item_for(space)
          return items if item.nil? || items.any? { |existing| existing[:id] == ITEM_ID }

          items + [item]
        end
      end
    end
  end
end
