# frozen_string_literal: true

# lib/tasks/seed_time_tracker_complete.rake

namespace :time_tracker do
  desc "Create complete time tracker ecosystem with spaces, components, tasks, activities, and user activities"
  task seed_complete: :environment do
    require "faker"

    organization = Decidim::Organization.first

    unless organization
      puts "No organization found. Please run rails db:seed first."
      exit
    end

    puts "🚀 Starting complete time tracker seeding..."

    spaces = create_participatory_spaces(organization)
    puts "✓ Created #{spaces.count} participatory spaces"

    time_trackers = []
    spaces.each do |space|
      tracker = create_time_tracker_component(space)
      time_trackers << tracker if tracker
    end
    puts "✓ Created #{time_trackers.count} time tracker components"

    all_tasks = []
    time_trackers.each do |tracker|
      tasks = create_tasks_for_tracker(tracker)
      all_tasks.concat(tasks)
    end
    puts "✓ Created #{all_tasks.count} tasks"

    all_activities = []
    all_tasks.each do |task|
      activities = create_activities_for_task(task)
      all_activities.concat(activities)
    end
    puts "✓ Created #{all_activities.count} activities"

    users = create_users_with_time_logs(organization, time_trackers)
    puts "✓ Created #{users.count} users with time logs"

    assignations = create_assignations(users, all_activities)
    puts "✓ Created #{assignations.count} activity assignations"

    time_logs = create_time_log_entries(assignations)
    puts "✓ Created #{time_logs} time log entries"

    puts "\n🎉 Complete! Time tracker ecosystem created successfully!"
    puts "\nSummary:"
    puts "  - Participatory Spaces: #{spaces.count}"
    puts "  - Time Trackers: #{time_trackers.count}"
    puts "  - Tasks: #{all_tasks.count}"
    puts "  - Activities: #{all_activities.count}"
    puts "  - Users: #{users.count}"
    puts "  - Assignations: #{assignations.count}"
    puts "  - Time Logs: #{time_logs}"
    puts "\nLogin credentials:"
    puts "  Email: tracker_user0@example.org"
    puts "  Password: decidim123456"
  end

  private

  def create_participatory_spaces(organization)
    spaces = []

    5.times do |i|
      space = Decidim::ParticipatoryProcess.create!(
        title: {
          en: "#{Faker::Company.buzzword.capitalize} Initiative #{i + 1}",
          es: "Iniciativa #{Faker::Company.buzzword.capitalize} #{i + 1}",
          ca: "Iniciativa #{Faker::Company.buzzword.capitalize} #{i + 1}"
        },
        subtitle: {
          en: Faker::Company.catch_phrase,
          es: Faker::Company.catch_phrase,
          ca: Faker::Company.catch_phrase
        },
        slug: "initiative-#{i + 1}-#{SecureRandom.hex(4)}",
        hashtag: "#initiative#{i + 1}",
        description: {
          en: Faker::Lorem.paragraph(sentence_count: 3),
          es: Faker::Lorem.paragraph(sentence_count: 3),
          ca: Faker::Lorem.paragraph(sentence_count: 3)
        },
        short_description: {
          en: Faker::Lorem.sentence,
          es: Faker::Lorem.sentence,
          ca: Faker::Lorem.sentence
        },
        organization: organization,
        published_at: rand(10..60).days.ago,
        start_date: rand(30..90).days.ago,
        end_date: rand(30..90).days.from_now
      )
      spaces << space
    end

    spaces
  end

  def create_time_tracker_component(space)
    component = Decidim::Component.create!(
      manifest_name: "time_tracker",
      name: {
        en: "#{Faker::Job.field} Time Tracking",
        es: "Seguimiento de Tiempo #{Faker::Job.field}",
        ca: "Seguiment de Temps #{Faker::Job.field}"
      },
      participatory_space: space,
      published_at: Time.current,
      settings: {}
    )

    command = Decidim::TimeTracker::Admin::CreateTimeTracker.new(component)
    command.call
    command.time_tracker
  rescue StandardError => e
    puts "Error creating time tracker: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    nil
  end

  def create_tasks_for_tracker(time_tracker)
    tasks = []

    rand(5..15).times do
      task = Decidim::TimeTracker::Task.create!(
        time_tracker: time_tracker,
        name: {
          en: Faker::Company.bs.titleize,
          es: Faker::Company.bs.titleize,
          ca: Faker::Company.bs.titleize
        }
      )
      tasks << task
    end

    tasks
  end

  def create_activities_for_task(task)
    activities = []

    rand(2..5).times do |_i|
      start_date = rand(5..30).days.ago
      activity = Decidim::TimeTracker::Activity.create!(
        task: task,
        description: {
          en: Faker::Lorem.sentence,
          es: Faker::Lorem.sentence,
          ca: Faker::Lorem.sentence
        },
        active: true,
        requests_start_at: start_date - 2.days,
        start_date: start_date,
        end_date: start_date + rand(7..30).days,
        max_minutes_per_day: [120, 180, 240, 480].sample,
        created_at: start_date - 3.days
      )
      activities << activity
    end

    activities
  end

  def create_users_with_time_logs(organization, time_trackers)
    users = []

    50.times do |i|
      user = Decidim::User.find_or_create_by!(email: "tracker_user#{i}@example.org") do |u|
        u.name = Faker::Name.name
        u.nickname = "tracker_user#{i}"
        u.password = "decidim123456"
        u.password_confirmation = "decidim123456"
        u.organization = organization
        u.confirmed_at = Time.current
        u.locale = [:en, :es, :ca].sample
        u.tos_agreement = true
        u.accepted_tos_version = organization.tos_version
      end

      users << user

      time_trackers.sample(rand(1..3)).each do |tracker|
        rand(3..10).times do
          create_questionnaire_answers(tracker, user)
        end
      end

      print "." if ((i + 1) % 10).zero?
    end

    puts ""
    users
  end

  def create_questionnaire_answers(time_tracker, user)
    questionnaire = time_tracker.questionnaire
    return unless questionnaire

    questionnaire.questions.each do |question|
      Decidim::Forms::Answer.create!(
        questionnaire: questionnaire,
        question: question,
        user: user,
        body: generate_answer_for_question(question),
        session_token: SecureRandom.hex(16),
        ip_hash: Faker::Internet.ip_v4_address,
        created_at: rand(1..30).days.ago
      )
    end
  rescue StandardError => e
    Rails.logger.debug { "Failed to create questionnaire answer: #{e.message}" }
  end

  def create_assignations(users, activities)
    assignations = []

    activities.select(&:active).each do |activity|
      selected_users = users.sample(rand(2..5))

      selected_users.each do |user|
        assignation = create_single_assignation(user, activity)
        assignations << assignation if assignation
      end
    end

    assignations
  end

  def create_single_assignation(user, activity)
    is_invited = rand(2).zero?
    status = determine_assignation_status

    Decidim::TimeTracker::Assignation.create!(
      decidim_user_id: user.id,
      activity_id: activity.id,
      status: status,
      invited_at: is_invited ? activity.created_at + 1.day : nil,
      invited_by_user_id: is_invited ? Decidim::User.find_by(admin: true)&.id : nil,
      requested_at: is_invited ? nil : activity.created_at + rand(1..3).days
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.debug { "Invalid assignation record: #{e.message}" }
    nil
  rescue StandardError => e
    Rails.logger.debug { "Failed to create assignation: #{e.message}" }
    nil
  end

  def determine_assignation_status
    rand_value = rand(100)
    case rand_value
    when 0..59 then "accepted"
    when 60..84 then "pending"
    else "rejected"
    end
  end

  def create_time_log_entries(assignations)
    count = 0
    errors = 0

    accepted_assignations = assignations.select { |a| a.status == "accepted" }

    puts "  Creating time logs for #{accepted_assignations.count} accepted assignations..."

    accepted_assignations.each do |assignation|
      entries_created = create_time_events_for_assignation(assignation)

      if entries_created.negative?
        errors += 1
      else
        count += entries_created
      end

      print "." if (count % 50).zero?
    end

    puts ""
    puts "  Skipped #{errors} assignations (no start_date or errors)" if errors.positive?
    count
  end

  def create_time_events_for_assignation(assignation)
    activity = assignation.activity
    return -1 unless activity.start_date

    num_entries = rand(3..10)
    num_entries.times do
      create_single_time_event(assignation, activity)
    end

    num_entries
  rescue StandardError => e
    Rails.logger.debug { "Error creating time events: #{e.message}" }
    -1
  end

  def create_single_time_event(assignation, activity)
    work_date = random_date_in_range(activity.start_date, activity.end_date || Time.zone.today)
    max_minutes = activity.max_minutes_per_day || 480
    minutes_worked = rand(30..max_minutes)
    total_seconds = minutes_worked * 60

    start_hour = rand(8..16)
    start_time = work_date.to_time.in_time_zone.change(hour: start_hour, min: rand(0..59))
    stop_time = start_time + total_seconds.seconds

    Decidim::TimeTracker::TimeEvent.create!(
      decidim_user_id: assignation.decidim_user_id,
      assignation_id: assignation.id,
      activity_id: activity.id,
      start: start_time.to_i,
      stop: stop_time.to_i,
      total_seconds: total_seconds,
      created_at: start_time,
      updated_at: stop_time
    )
  end

  def random_date_in_range(start_date, end_date)
    return start_date unless end_date && end_date > start_date

    days_between = (end_date - start_date).to_i
    start_date + rand(0..days_between).days
  end

  def generate_answer_for_question(question)
    answer_generators = {
      "short_answer" => -> { generate_short_answer },
      "long_answer" => -> { Faker::Lorem.paragraph(sentence_count: 3) },
      "single_option" => -> { question.answer_options.sample&.id&.to_s },
      "multiple_option" => -> { question.answer_options.sample(rand(1..3)).map { |opt| opt.id.to_s } },
      "number" => -> { rand(1..8).to_s },
      "date" => -> { rand(1..30).days.ago.to_date.to_s }
    }

    generator = answer_generators[question.question_type]
    generator ? generator.call : Faker::Lorem.word
  end

  def generate_short_answer
    [
      "Completed documentation", "Updated codebase", "Reviewed pull request",
      "Meeting with stakeholders", "Bug fixing", "Feature development",
      "Code review", "Testing", "Deployment", "Planning session"
    ].sample
  end
end
