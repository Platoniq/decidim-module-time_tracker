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
    tasks = Decidim::TimeTracker::Task.where(time_tracker: time_tracker)

    raise StandardError, "Can't remove this component, there are resources associated" if [answers, assignation_answers, tasks].any?(&:any?)
  end

  # These actions permissions can be configured in the admin panel
  # component.actions = %w()

  component.settings(:global) do |settings|
    # Add your global settings
    # Available types: :integer, :boolean
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :max_number_of_assignations, type: :integer
    settings.attribute :tos, type: :text, translated: true, editor: true
    settings.attribute :tasks_label, type: :string, translated: true, editor: true
    settings.attribute :activities_label, type: :string, translated: true, editor: true
    settings.attribute :assignations_label, type: :string, translated: true, editor: true
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

  component.register_stat :activities_count, primary: true, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, start_at, end_at|
    tasks = Decidim::TimeTracker::Task.joins(:time_tracker).where(decidim_time_trackers: { decidim_component_id: components })
    activities = Decidim::TimeTracker::Activity.where(task: tasks).active
    activities = activities.where("start_date >= ?", start_at) if start_at.present?
    activities = activities.where("start_date <= ?", end_at) if end_at.present?
    activities.count
  end

  component.register_stat :tasks_count, tag: :tasks, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, _start_at, _end_at|
    tasks = Decidim::TimeTracker::Task.joins(:time_tracker).where(decidim_time_trackers: { decidim_component_id: components })
    tasks.count
  end

  component.register_stat :assignees_count, tag: :assignees, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    tasks = Decidim::TimeTracker::Task.joins(:time_tracker).where(decidim_time_trackers: { decidim_component_id: components })
    assignations = Decidim::TimeTracker::Assignation.joins(:activity).where(decidim_time_tracker_activities: { task_id: tasks })
    assignations = assignations.where("created_at >= ?", start_at) if start_at.present?
    assignations = assignations.where("created_at <= ?", end_at) if end_at.present?
    assignations.count
  end

  component.exports :time_tracker_activity_questionnaire_answers do |exports|
    exports.collection do |f|
      time_tracker = Decidim::TimeTracker::TimeTracker.find_by(component: f)

      Decidim::Forms::Answer.joins(:questionnaire).where(questionnaire: time_tracker.activity_questionnaire)
                            .group_by do |answer|
        answer.session_token.split("-").first
      end.values
    end

    exports.serializer Decidim::TimeTracker::TimeTrackerActivityQuestionnaireAnswersSerializer

    exports.formats %w(CSV JSON Excel FormPDF)
  end

  component.exports :time_tracker_assignee_questionnaire_answers do |exports|
    exports.collection do |f|
      time_tracker = Decidim::TimeTracker::TimeTracker.find_by(component: f)
      Decidim::Forms::QuestionnaireUserAnswers.for(time_tracker.assignee_questionnaire)
    end

    exports.serializer Decidim::Forms::UserAnswersSerializer

    exports.formats %w(CSV JSON Excel FormPDF)
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
        max_number_of_assignations: 10,
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

    time_tracker = Decidim::TimeTracker::TimeTracker.create!(
      component: component,
      questionnaire: Decidim::Forms::Questionnaire.new(
        tos: Decidim::Faker::Localized.sentence(10),
        title: Decidim::Faker::Localized.sentence(4),
        description: Decidim::Faker::Localized.sentence(10)
      )
    )

    assignee_data = Decidim::TimeTracker::AssigneeData.create!(
      time_tracker: time_tracker,
      questionnaire: Decidim::Forms::Questionnaire.new(
        tos: Decidim::Faker::Localized.sentence(10),
        title: Decidim::Faker::Localized.sentence(4),
        description: Decidim::Faker::Localized.sentence(10)
      )
    )

    questionnaire_parents = [time_tracker, assignee_data]

    questionnaire_parents.each do |resource|
      Decidim::Forms::Question.create!([
                                         {
                                           questionnaire: resource.questionnaire,
                                           question_type: "short_answer",
                                           body: Decidim::Faker::Localized.sentence(5),
                                           position: 1
                                         },
                                         {
                                           questionnaire: resource.questionnaire,
                                           question_type: "single_option",
                                           body: Decidim::Faker::Localized.sentence(5),
                                           position: 2,
                                           answer_options: 3.times.to_a.map { Decidim::Forms::AnswerOption.new(body: Decidim::Faker::Localized.sentence(5)) }
                                         }
                                       ])
    end

    # Create some tasks
    3.times do
      task = Decidim.traceability.create!(
        Decidim::TimeTracker::Task,
        admin_user,
        name: Decidim::Faker::Localized.sentence(2),
        time_tracker: time_tracker
      )

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

        # Add assignations
        Decidim::User.confirmed.not_deleted.not_managed.where(admin: false).sample(10).each do |user|
          assignee = Decidim.traceability.create!(
            Decidim::TimeTracker::Assignee,
            admin_user,
            user: user
          )

          Decidim.traceability.create!(
            Decidim::TimeTracker::TosAcceptance,
            admin_user,
            assignee: assignee,
            time_tracker: time_tracker
          )

          Decidim.traceability.create!(
            Decidim::TimeTracker::Assignation,
            admin_user,
            activity: activity,
            user: user,
            status: [:accepted, :rejected, :pending].sample,
            invited_at: 1.week.ago,
            invited_by_user: admin_user
          )

          questionnaire_parents.each do |resource|
            resource.questionnaire.questions.each do |question|
              answer = Decidim::Forms::Answer.new(
                questionnaire: resource.questionnaire,
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
end
