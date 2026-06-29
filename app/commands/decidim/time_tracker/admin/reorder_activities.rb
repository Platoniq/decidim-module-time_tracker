# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when reordering activities.
      class ReorderActivities < Decidim::Command
        # Public: Initializes the command.
        #
        # collection - the collection of activities to reorder
        # order - an Array of IDs in the new order
        def initialize(collection, order)
          @collection = collection
          @order = order
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the collection.
        # - :invalid if the order is empty.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if @order.blank?

          reorder_activities
          broadcast(:ok, @collection)
        end

        private

        def reorder_activities
          @order.each_with_index do |id, index|
            activity = @collection.find_by(id: id)
            # Reordering only bumps the weight column; validations are intentionally skipped.
            activity.update_column(:weight, index) if activity # rubocop:disable Rails/SkipsModelValidations
          end
        end
      end
    end
  end
end
