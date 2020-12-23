# frozen_string_literal: true

module Decidim
  module TimeTracker
    # The data store for terms of service acceptance in the Decidim::TimeTracker component.
    class TosAcceptance < ApplicationRecord
      self.table_name = :decidim_time_tracker_tos_acceptances

      belongs_to :assignee,
                 class_name: "Decidim::TimeTracker::Assignee"
      
      belongs_to :time_tracker,
                 class_name: "Decidim::TimeTracker::TimeTracker"

    end
  end
end
