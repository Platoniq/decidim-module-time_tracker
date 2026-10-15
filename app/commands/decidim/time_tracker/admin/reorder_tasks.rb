# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command that reorders a collection of tasks
      class ReorderTasks < Decidim::Command
        # Public: Initializes the command.
        #
        # tasks - the tasks to reorder
        # order - an Array holding the order of IDs of the tasks
        def initialize(tasks, order)
          @tasks = tasks
          @order = order
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the data was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless valid_params?

          reorder_tasks
          broadcast(:ok)
        end

        private

        attr_reader :tasks, :order

        def valid_params?
          order.present? && tasks.present?
        end

        def reorder_tasks
          transaction do
            order.each_with_index do |id, index|
              task = tasks.find_by(id: id)
              task.update!(weight: index + 1) if task.present?
            end
          end
        end
      end
    end
  end
end
