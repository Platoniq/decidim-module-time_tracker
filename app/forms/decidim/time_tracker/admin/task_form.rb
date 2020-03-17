# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update task from Decidim's admin panel.
      class TaskForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :name, String

        validates :name, translatable_presence: true

        def organizer
          @organizer ||= current_organization.users.find_by(id: organizer_id)
        end

        alias component current_component

        # Finds the Scope from the given decidim_scope_id, uses participatory space scope if missing.
        #
        # Returns a Decidim::Scope
        def scope
          @scope ||= @decidim_scope_id ? current_participatory_space.scopes.find_by(id: @decidim_scope_id) : current_participatory_space.scope
        end

        # Scope identifier
        #
        # Returns the scope identifier related to the meeting
        def decidim_scope_id
          @decidim_scope_id || scope&.id
        end

        private

        def scope_belongs_to_participatory_space_scope
          errors.add(:decidim_scope_id, :invalid) if current_participatory_space.out_of_scope?(scope)
        end
      end
    end
  end
end
