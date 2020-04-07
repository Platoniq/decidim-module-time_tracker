# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # A command with all the business logic when creating a assignee
      class CreateAssignee < Rectify::Command
        def initialize(form, activity)
          @form = form
          @activity = activity
        end

        # Creates the meeting if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if @form.invalid?

          ActiveRecord::Base.transaction do
            @user ||= existing_user || new_user
            create_assignee
          end

          broadcast(:ok)
        end

        def create_assignee
          Decidim.traceability.create!(
            Decidim::TimeTracker::Assignee,
            @form.current_user,
            activity: @activity,
            user: @user,
            status: :pending,
            invited_at: Time.current,
            invited_by_user: @form.current_user
          )
        end

        def existing_user
          return @existing_user if defined?(@existing_user)

          @existing_user = User.find_by(
            email: @form.email,
            organization: @activity.task.component.organization
          )

          InviteUserAgain.call(@existing_user, "invite_admin") if @existing_user && !@existing_user.invitation_accepted?

          @existing_user
        end

        def new_user
          @new_user ||= InviteUser.call(user_form) do
            on(:ok) do |user|
              return user
            end
          end
        end

        def user_form
          OpenStruct.new(name: @form.name,
                         email: @form.email.downcase,
                         organization: @activity.task.component.organization,
                         admin: false,
                         invited_by: @form.current_user,
                         invitation_instructions: "invite_admin")
        end
      end
    end
  end
end
