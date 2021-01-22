# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TimeTracker
    module Admin
      module FilterableAssignations
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            assignations_collection
          end

          def search_field_predicate
            :user_name_or_user_nickname_cont
          end

          def filters
            [:activity_id_eq, :activity_task_id_eq]
          end

          def filters_with_values
            {
              activity_id_eq: time_tracker.activities.pluck(:id),
              activity_task_id_eq: time_tracker.tasks.pluck(:id)
            }
          end

          def dynamically_translated_filters
            [:activity_id_eq, :activity_task_id_eq]
          end

          def translated_activity_id_eq(id)
            translated_attribute(Activity.find_by(id: id).description)
          end

          def translated_activity_task_id_eq(id)
            translated_attribute(Task.find_by(id: id).name)
          end
        end
      end
    end
  end
end
