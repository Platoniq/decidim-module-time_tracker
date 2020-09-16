# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when an admin exports time tracker to
      # create an accountability component.
      class ExportTimeTracker < Rectify::Command
        # Public: Initializes the command.
        def initialize(current_component, current_user)
          @component = current_component
          @user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid when we couldn't proceed.
        #
        # Returns the accountability component.
        def call
          create_component
          export_time_tracker
          broadcast(:ok, @accountability_component)
        end

        private

        attr_reader :component

        def create_component
          params = {
            name: {
              en: "Time Tracker Accountability"
            },
            manifest_name: :accountability,
            published_at: Time.current,
            participatory_space: @component.participatory_space,
            settings: {
              categories_label: {
                en: "Project"
              },
              subcategories_label: {
                en: "Activity"
              }
            }
          }

          @accountability_component = Decidim.traceability.perform_action!("publish", Decidim::Component, @user, visibility: "all") do
            Decidim::Component.create!(params)
          end

          Decidim::Accountability::Status.create!(
            component: @accountability_component,
            name: { en: "Not started" },
            key: "not_started"
          ) do |status|
            @not_started = status
          end

          Decidim::Accountability::Status.create!(
            component: @accountability_component,
            name: { en: "Work in progress" },
            key: "work_in_progress"
          ) do |status|
            @work_in_progress = status
          end

          Decidim::Accountability::Status.create!(
            component: @accountability_component,
            name: { en: "Completed" },
            key: "completed"
          ) do |status|
            @completed = status
          end
        end

        def export_time_tracker
          tasks.each do |task|
            params_category = {
              name: task.name,
              weight: 0,
              description: task.name,
              participatory_space: current_participatory_space
            }

            category = Decidim.traceability.create!(
              Decidim::Category,
              @user,
              params_category
            )

            status = @not_started
            status = @work_in_progress unless task.activities.joins(:time_entries).empty?
            status = @completed if task.activities.where("decidim_time_tracker_activities.end_date > ?", Time.zone.today).empty?

            params_task = {
              component: @accountability_component,
              title: task.name,
              category: category,
              status: @not_started
            }

            result = Decidim.traceability.create!(
              Decidim::Accountability::Result,
              @user,
              params_task,
              visibility: "all"
            )

            task_activities(task).each do |activity|
              status = @not_started
              status = @work_in_progress unless activity.time_entries.nil?
              status = @completed if activity.end_date < Time.zone.today

              params_activity = {
                component: @accountability_component,
                parent_id: result.id,
                title: activity.description,
                start_date: activity.start_date,
                end_date: activity.end_date,
                category: category,
                status: status
              }

              Decidim.traceability.create!(
                Decidim::Accountability::Result,
                @user,
                params_activity,
                visibility: "all"
              )
            end
          end
        end

        def tasks
          Decidim::TimeTracker::Task.where(component: @component)
        end

        def task_activities(task)
          Decidim::TimeTracker::Activity.where(task: task)
        end

        def activities_assignees(activity)
          Decidim::TimeTracker::Assignee.where(activity: activity)
        end
      end
    end
  end
end
