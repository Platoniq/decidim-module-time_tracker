# frozen_string_literal: true

require_dependency "decidim/components/namer"

Decidim.register_component(:time_tracker) do |component|
  component.engine = Decidim::TimeTracker::Engine
  component.admin_engine = Decidim::TimeTracker::AdminEngine
  component.admin_stylesheet = "decidim/time_tracker/admin/time_tracker"
  component.icon = "decidim/time_tracker/icon.svg"
  component.permissions_class_name = "Decidim::TimeTracker::Permissions"

  component.data_portable_entities = ["Decidim::TimeTracker::Milestone"]

  component.newsletter_participant_entities = ["Decidim::TimeTracker::Milestone"]

  component.on(:copy) do |context|
    Decidim::TimeTracker::Admin::CreateTimeTracker.call(context[:new_component]) do
      on(:invalid) { raise "Can't create Time Tracker" }
    end
  end

  component.on(:create) do |instance|
    Decidim::TimeTracker::Admin::CreateTimeTracker.call(instance) do
      on(:invalid) { raise "Can't create Time Tracker" }
    end
  end

  component.on(:before_destroy) do |instance|
    # Code executed before removing the component
    time_tracker = Decidim::TimeTracker::TimeTracker.find_by(decidim_component_id: instance.id)

    answers = Decidim::Forms::Answer.where(questionnaire: time_tracker.questionnaire)
    assignee_answers = Decidim::Forms::Answer.where(questionnaire: time_tracker.assignee_questionnaire)
    tasks = Decidim::TimeTracker::Task.where(time_tracker: time_tracker)

    raise StandardError, "Can't remove this component, there are resources associated" if [answers, assignee_answers, tasks].any?(&:any?)
  end

  # These actions permissions can be configured in the admin panel
  # component.actions = %w()

  component.settings(:global) do |settings|
    # Add your global settings
    # Available types: :integer, :boolean
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :max_number_of_assignees, type: :integer
    settings.attribute :tos, type: :text, translated: true, editor: true
    settings.attribute :tasks_label, type: :string, translated: true, editor: true
    settings.attribute :activities_label, type: :string, translated: true, editor: true
    settings.attribute :assignees_label, type: :string, translated: true, editor: true
    settings.attribute :time_events_label, type: :string, translated: true, editor: true
    settings.attribute :milestones_label, type: :string, translated: true, editor: true
  end

  component.settings(:step) do |settings|
    # Add your settings per step
    settings.attribute :announcement, type: :text, translated: true, editor: true
  end

  component.register_resource(:milestone) do |resource|
    # Register a optional resource that can be references from other resources.
    resource.model_class_name = "Decidim::TimeTracker::Milestone"
    # TODO!:
    # resource.template = "decidim/time_tracker/time_tracker/linked_tasks"
    resource.card = "decidim/time_tracker/milestone"
    # resource.actions = %w(create)
    # resource.searchable = true
  end

  # component.register_stat :some_stat do |context, start_at, end_at|
  #   # Register some stat number to the application
  # end

  component.exports :time_tracker_questionnaire_answers do |exports|
    exports.collection do |f|
      time_tracker = Decidim::TimeTracker::TimeTracker.find_by(component: f)

      Decidim::Forms::Answer.joins(:questionnaire).where(questionnaire: time_tracker.questionnaire)
                            .group_by do |answer|
        answer.session_token.split("-").first # TODO
      end.values
    end

    exports.serializer Decidim::TimeTracker::TimeTrackerQuestionnaireAnswersSerializer
  end

  component.seeds do |participatory_space|
    # Add some seeds for this component
    admin_user = Decidim::User.find_by(
      organization: participatory_space.organization,
      email: "admin@example.org"
    )

    params = {
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :time_tracker).i18n_name,
      manifest_name: :time_tracker,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        max_number_of_assignees: 10,
        tos: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
          Decidim::Faker::Localized.paragraph(3)
        end
      }
    }

    component = Decidim.traceability.perform_action!(
      "publish",
      Decidim::Component,
      admin_user,
      visibility: "all"
    ) do
      Decidim::Component.create!(params)
    end

    time_tracker = Decidim::TimeTracker::TimeTracker.create(
      component: component,
      questionnaire: Decidim::Forms::Questionnaire.new(
        tos: Decidim::Faker::Localized.sentence(10),
        title: Decidim::Faker::Localized.sentence(4),
        description: Decidim::Faker::Localized.sentence(10)
      )
    )

    # Create some tasks
    3.times do
      task = Decidim.traceability.create!(
        Decidim::TimeTracker::Task,
        admin_user,
        name: Decidim::Faker::Localized.sentence(2),
        time_tracker: time_tracker
      )

      Decidim::Forms::Question.create!([
                                         {
                                           questionnaire: task.questionnaire,
                                           question_type: "short_answer",
                                           body: Decidim::Faker::Localized.sentence(5),
                                           position: 1
                                         },
                                         {
                                           questionnaire: task.questionnaire,
                                           question_type: "single_option",
                                           body: Decidim::Faker::Localized.sentence(5),
                                           position: 2,
                                           answer_options: 3.times.to_a.map { Decidim::Forms::AnswerOption.new(body: Decidim::Faker::Localized.sentence(5)) }
                                         }
                                       ])

      # Create activites for these tasks
      5.times do |index|
        activity = Decidim.traceability.create!(
          Decidim::TimeTracker::Activity,
          admin_user,
          description: Decidim::Faker::Localized.sentence(4),
          active: [true, false].sample,
          start_date: 1.week.ago + (index * 1.week),
          end_date: 1.week.from_now + (index * 1.week),
          max_minutes_per_day: [15, 30, 45, 60].sample,
          requests_start_at: 1.week.ago + (index * 3.days),
          task: task
        )

        # Add assignees
        Decidim::User.confirmed.not_deleted.not_managed.where(admin: false).sample(10).each do |user|
          Decidim.traceability.create!(
            Decidim::TimeTracker::Assignee,
            admin_user,
            activity: activity,
            user: user,
            status: [:accepted, :rejected, :pending].sample,
            invited_at: 1.week.ago,
            invited_by_user: admin_user,
            tos_accepted_at: [nil, Time.zone.now].sample
          )
          task.questionnaire.questions.each do |question|
            answer = Decidim::Forms::Answer.new(
              questionnaire: task.questionnaire,
              question: question,
              session_token: activity.session_token(user)
            )

            answer.body = "My name is #{user.nickname}" if question.question_type == "short_answer"

            answer.save!

            next unless question.question_type == "single_option"

            Decidim::Forms::AnswerChoice.create(
              answer: answer,
              answer_option: question.answer_options.sample,
              body: question.body["en"]
            )
          end
        end
      end
    end
  end
end
