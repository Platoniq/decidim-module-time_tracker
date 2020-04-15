# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class AssigneeForm < Decidim::Form
        mimic :assignee

        attribute :user_id, Integer
        attribute :existing_user, Boolean, default: false
        attribute :name, String
        attribute :email, String

        validates :name, presence: true
        validates :email, presence: true, unless: proc { |object| object.existing_user }
        validates :user, presence: true, if: proc { |object| object.existing_user }


        def map_model(model)
          self.user_id = model.decidim_user_id
          self.existing_user = user_id.present?
        end

        def user
          @user ||= current_organization.users.find_by(id: user_id)
        end
      end
    end
  end
end
