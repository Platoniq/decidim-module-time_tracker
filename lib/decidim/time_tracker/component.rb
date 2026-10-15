# frozen_string_literal: true

require_dependency "decidim/components/namer"

Decidim.register_component(:time_tracker) do |component|
  component.engine = Decidim::TimeTracker::Engine
  component.admin_engine = Decidim::TimeTracker::AdminEngine
  component.icon = "media/images/decidim_time_tracker.svg"
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

  # A time tracker that holds any work cannot be deleted: its tasks carry
  # people's tracked time, certifications and badge progress. An empty one is
  # removed together with the records CreateTimeTracker made for it, which no
  # foreign key would otherwise clean up.
  component.on(:before_destroy) do |instance|
    time_tracker = Decidim::TimeTracker::TimeTracker.find_by(decidim_component_id: instance.id)
    next if time_tracker.blank?

    assignee_data = time_tracker.assignee_data
    questionnaires = [time_tracker.questionnaire, assignee_data&.questionnaire].compact

    holds_work = time_tracker.tasks.exists? || questionnaires.any? { |questionnaire| questionnaire.answers.exists? }
    raise StandardError, "Can't remove this component, there are resources associated" if holds_work

    Decidim::TimeTracker::TosAcceptance.where(time_tracker:).delete_all
    assignee_data&.destroy!
    time_tracker.destroy!
  end

  # These actions permissions can be configured in the admin panel
  # component.actions = %w()

  component.settings(:global) do |settings|
    # Add your global settings
    # Available types: :integer, :boolean
    settings.attribute :announcement, type: :text, translated: true, editor: true
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
    activities = activities.where(start_date: start_at..) if start_at.present?
    activities = activities.where(start_date: ..end_at) if end_at.present?
    activities.count
  end

  component.register_stat :tasks_count, tag: :tasks, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, _start_at, _end_at|
    tasks = Decidim::TimeTracker::Task.joins(:time_tracker).where(decidim_time_trackers: { decidim_component_id: components })
    tasks.count
  end

  component.register_stat :assignees_count, tag: :assignees, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    tasks = Decidim::TimeTracker::Task.joins(:time_tracker).where(decidim_time_trackers: { decidim_component_id: components })
    assignations = Decidim::TimeTracker::Assignation.joins(:activity).where(decidim_time_tracker_activities: { task_id: tasks })
    assignations = assignations.where(created_at: start_at..) if start_at.present?
    assignations = assignations.where(created_at: ..end_at) if end_at.present?
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
      participatory_space:
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
      component:,
      questionnaire: Decidim::Forms::Questionnaire.new(
        tos: Decidim::Faker::Localized.sentence(word_count: 10),
        title: Decidim::Faker::Localized.sentence(word_count: 4),
        description: Decidim::Faker::Localized.sentence(word_count: 10)
      )
    )

    assignee_data = Decidim::TimeTracker::AssigneeData.create!(
      time_tracker:,
      questionnaire: Decidim::Forms::Questionnaire.new(
        tos: Decidim::Faker::Localized.sentence(word_count: 10),
        title: Decidim::Faker::Localized.sentence(word_count: 4),
        description: Decidim::Faker::Localized.sentence(word_count: 10)
      )
    )

    questionnaire_parents = [time_tracker, assignee_data]

    questionnaire_parents.each do |resource|
      Decidim::Forms::Question.create!([
                                         {
                                           questionnaire: resource.questionnaire,
                                           question_type: "short_answer",
                                           body: Decidim::Faker::Localized.sentence(word_count: 5),
                                           position: 1
                                         },
                                         {
                                           questionnaire: resource.questionnaire,
                                           question_type: "single_option",
                                           body: Decidim::Faker::Localized.sentence(word_count: 5),
                                           position: 2,
                                           answer_options: 3.times.to_a.map { Decidim::Forms::AnswerOption.new(body: Decidim::Faker::Localized.sentence(word_count: 5)) }
                                         }
                                       ])
    end

    # Create some tasks
    3.times do
      task = Decidim.traceability.create!(
        Decidim::TimeTracker::Task,
        admin_user,
        name: Decidim::Faker::Localized.sentence(word_count: 2),
        time_tracker:
      )

      # Create activites for these tasks
      5.times do |index|
        activity = Decidim.traceability.create!(
          Decidim::TimeTracker::Activity,
          admin_user,
          description: Decidim::Faker::Localized.sentence(word_count: 4),
          active: [true, false].sample,
          # Staggered so most activities are under way and have tracked time.
          start_date: (4 - index).weeks.ago,
          end_date: (4 - index).weeks.ago + 6.weeks,
          max_minutes_per_day: [15, 30, 45, 60].sample,
          requests_start_at: (4 - index).weeks.ago - 3.days,
          min_events: [1, 2].sample,
          min_duration_minutes_per_event: [10, 15].sample,
          task:
        )

        # Add assignations
        Decidim::User.confirmed.not_deleted.not_managed.where(admin: false).sample(10).each do |user|
          assignee = Decidim.traceability.create!(
            Decidim::TimeTracker::Assignee,
            admin_user,
            user:
          )

          Decidim.traceability.create!(
            Decidim::TimeTracker::TosAcceptance,
            admin_user,
            assignee:,
            time_tracker:
          )

          assignation = Decidim.traceability.create!(
            Decidim::TimeTracker::Assignation,
            admin_user,
            activity:,
            user:,
            status: [:accepted, :rejected, :pending].sample,
            invited_at: 1.week.ago,
            invited_by_user: admin_user
          )

          # Accepted volunteers have tracked some sessions, of different
          # lengths and at different times, and filed the completions those
          # earn, as stopping the timer would; an admin has verified some.
          if assignation.accepted? && activity.start_date < 1.day.ago
            # One session a day at most, so none goes past the daily cap.
            (activity.start_date.to_date..1.day.ago.to_date).to_a.sample(rand(0..4)).each do |day|
              started = Time.zone.local(day.year, day.month, day.day, rand(8..20), rand(0..59))
              minutes = rand(10..activity.max_minutes_per_day)
              Decidim::TimeTracker::TimeEvent.create!(
                assignation:, activity:, user:,
                start: started.to_i, stop: started.to_i + (minutes * 60), total_seconds: minutes * 60
              )
            end

            qualifying = activity.time_events.where(user:)
                                 .where(total_seconds: (activity.min_duration_minutes_per_event * 60)..)
                                 .order(:start).to_a
            qualifying.each_slice(activity.min_events).select { |batch| batch.size == activity.min_events }.each do |batch|
              requested_at = Time.zone.at(batch.last.stop) + rand(1..30).minutes
              completion = assignation.completions.create!(requested_at:)
              verified_at = requested_at + rand(2..72).hours
              completion.update!(verified_at:, verified_by: admin_user) if rand < 0.6 && verified_at.past?
            end
            assignation.sync_completed_at!
          end

          questionnaire_parents.each do |resource|
            resource.questionnaire.questions.each do |question|
              answer = Decidim::Forms::Answer.new(
                questionnaire: resource.questionnaire,
                question:,
                session_token: activity.session_token(user)
              )

              answer.body = "My name is #{user.nickname}" if question.question_type == "short_answer"

              answer.save!

              next unless question.question_type == "single_option"

              Decidim::Forms::AnswerChoice.create(
                answer:,
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
