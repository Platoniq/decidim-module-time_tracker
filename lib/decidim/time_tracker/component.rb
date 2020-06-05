# frozen_string_literal: true

require_dependency "decidim/components/namer"

Decidim.register_component(:time_tracker) do |component|
  component.engine = Decidim::TimeTracker::Engine
  component.admin_engine = Decidim::TimeTracker::AdminEngine
  component.icon = "decidim/time_tracker/icon.svg"
  component.permissions_class_name = "Decidim::TimeTracker::Permissions"

  component.on(:before_destroy) do |instance|
    # Code executed before removing the component
    raise StandardEerror, "Can't remove this component" if Decidim::TimeTracker::Task.where(component: instance).any?
  end

  # These actions permissions can be configured in the admin panel
  # component.actions = %w()

  component.settings(:global) do |settings|
    # Add your global settings
    # Available types: :integer, :boolean
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :max_number_of_assignees, type: :integer
    settings.attribute :tos, type: :text, translated: true, editor: true
  end

  component.settings(:step) do |settings|
    # Add your settings per step
    settings.attribute :announcement, type: :text, translated: true, editor: true
  end

  component.register_resource(:assignee) do |resource|
    # Register a optional resource that can be references from other resources.
    resource.model_class_name = "Decidim::TimeTracker::Assignee"
    # TODO!:
    # resource.template = "decidim/time_tracker/time_tracker/linked_tasks"
    resource.card = "decidim/time_tracker/assignee"
    # resource.actions = %w(join)
    # resource.searchable = true
  end

  # component.register_stat :some_stat do |context, start_at, end_at|
  #   # Register some stat number to the application
  # end

  # component.seeds do |participatory_space|
  #   # Add some seeds for this component
  # end
end

Decidim.register_global_engine(
  :decidim_time_tracker, # this is the name of the global method to access engine routes
  ::Decidim::TimeTracker::DirectoryEngine,
  at: "/timetracker"
)
