# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for an assignee datum in the Decidim::TimeTracker component.
    class AssigneeDatum < ApplicationRecord
      self.table_name = :decidim_time_tracker_assignee_data

      belongs_to :assignee,
                 foreign_key: "decidim_time_tracker_assignee_id",
                 class_name: "Decidim::TimeTracker::Assignee"
      
      enum data_types: %i[string number]
    end
  end
end