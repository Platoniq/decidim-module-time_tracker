# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssigneeForm < Decidim::Form
        attribute :name, String
        attribute :email, String

        validates :name, presence: true
        validates :email, presence: true
      end
    end
  end
end
