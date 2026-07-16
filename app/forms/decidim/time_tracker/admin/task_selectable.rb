# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # Shared behavior for admin forms that let the admin pick tasks from
      # every time tracker component of the organization.
      module TaskSelectable
        extend ActiveSupport::Concern

        included do
          attribute :task_ids, [Integer]
        end

        def tasks
          available_tasks.select { |task| task_ids.include?(task.id) }
        end

        # Every task of the organization, across all time tracker components.
        # The organization is reached through the component's participatory
        # space (polymorphic), so it is filtered in Ruby; admin-scale data.
        def available_tasks
          @available_tasks ||= Decidim::TimeTracker::Task
                               .includes(time_tracker: :component)
                               .order(:id)
                               .select { |task| task.component&.organization == current_organization }
        end

        # Options for a grouped select, one group per component.
        def grouped_task_options
          available_tasks.group_by(&:component).map do |component, tasks|
            group_label = "#{translated_attribute(component.participatory_space.title)} — #{translated_attribute(component.name)}"
            [group_label, tasks.map { |task| [translated_attribute(task.name), task.id] }]
          end
        end
      end
    end
  end
end
