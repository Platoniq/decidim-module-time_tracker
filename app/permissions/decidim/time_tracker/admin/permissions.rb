# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin

          allowed_task_action?
          allowed_skill_action?
          allowed_badge_action?
          allowed_questionnaire_action?
          allowed_activity_action?
          allowed_assignation_action?
          allowed_completion_action?

          permission_action
        end

        # Skills and badges belong to the organization and are shared by every
        # time tracker in it, but they are managed from inside a component.
        # Anyone who can administer one component may read them, to attach
        # skills to their own tasks; changing them is reserved to organization
        # admins, because an edit re-evaluates — and a deletion revokes — the
        # certifications of participants in every other space too.
        def allowed_skill_action?
          return false unless permission_action.subject.in? [:skill, :skills]

          allow_organization_wide_action!
        end

        def allowed_badge_action?
          return false unless permission_action.subject == :time_tracker_badge

          allow_organization_wide_action!
        end

        def allow_organization_wide_action!
          case permission_action.action
          when :index
            permission_action.allow!
          when :create, :update, :destroy
            permission_action.allow! if user.admin?
          end
        end

        def allowed_task_action?
          return false unless permission_action.subject.in? [:task, :tasks]

          case permission_action.action
          when :index, :create, :update, :destroy
            permission_action.allow!
          end
        end

        def allowed_questionnaire_action?
          return false unless permission_action.subject.in? [:questionnaire, :questionnaire_answers]

          case permission_action.subject
          when :questionnaire
            case permission_action.action
            when :export_answers, :update, :preview
              permission_action.allow!
            end
          when :questionnaire_answers
            case permission_action.action
            when :show, :index, :export_response
              permission_action.allow!
            end
          end
        end

        def allowed_activity_action?
          return false unless permission_action.subject.in? [:activity, :activities]

          case permission_action.action
          when :index, :create, :update, :destroy
            permission_action.allow!
          end
        end

        def allowed_completion_action?
          return false unless permission_action.subject == :completion

          case permission_action.action
          when :verify, :dismiss
            permission_action.allow!
          end
        end

        def allowed_assignation_action?
          return false unless permission_action.subject.in? [:assignation, :assignations]

          case permission_action.action
          when :update
            permission_action.allow! if assignation.can_change_status?
          when :complete
            permission_action.allow! if assignation.accepted?
          when :index, :create, :destroy
            permission_action.allow!
          end
        end

        def assignation
          @assignation ||= context.fetch(:assignation, nil)
        end
      end
    end
  end
end
