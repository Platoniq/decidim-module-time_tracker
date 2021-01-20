# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/forms/test/factories"

FactoryBot.define do
  factory :time_tracker_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :time_tracker).i18n_name }
    manifest_name { :time_tracker }
    participatory_space { create(:participatory_process, :with_steps) }
  end

  factory :time_tracker, class: "Decidim::TimeTracker::TimeTracker" do
    component factory: :time_tracker_component
    questionnaire

    after(:create) do |time_tracker, _evaluator|
      create :assignee_data, time_tracker: time_tracker
    end
  end

  factory :assignee_data, class: "Decidim::TimeTracker::AssigneeData" do
    time_tracker
    questionnaire
  end

  factory :activity, class: "Decidim::TimeTracker::Activity" do
    task { create(:task) }
    description { Decidim::Faker::Localized.sentence(3) }
    active { true }
    start_date { 1.day.ago }
    end_date { 1.month.from_now }
    max_minutes_per_day { 60 }
    requests_start_at { Time.zone.today }

    trait :with_assignations do
      after(:create) do |activity, _evaluator|
        create_list(:assignation, 2, :pending, activity: activity)
        create_list(:assignation, 3, :accepted, activity: activity)
        create_list(:assignation, 1, :rejected, activity: activity)
      end
    end

    trait :inactive do
      active { false }
    end

    trait :closed do
      requests_start_at { 1.month.ago }
      start_date { 1.month.ago }
      end_date { 1.day.ago }
    end
  end

  factory :assignation, class: "Decidim::TimeTracker::Assignation" do
    user { create(:user) }
    activity { create(:activity) }
    status { :accepted }
    invited_at { 1.month.ago }
    invited_by_user { create(:user) }
    requested_at { 2.months.ago }

    trait :pending do
      status { :pending }
    end

    trait :accepted do
      status { :accepted }
    end

    trait :rejected do
      status { :rejected }
    end
  end

  factory :milestone, class: "Decidim::TimeTracker::Milestone" do
    activity { create(:activity) }
    user { create(:user) }
    title { Decidim::Faker::Localized.word }
    description { Decidim::Faker::Localized.sentence(3) }
  end

  factory :task, class: "Decidim::TimeTracker::Task" do
    time_tracker
    name { Decidim::Faker::Localized.word }
  end

  factory :time_event, class: "Decidim::TimeTracker::TimeEvent" do
    assignation { create(:assignation) }
    activity { create(:activity) }
    start { Time.current }
    stop { nil }
    total_seconds { stop.present? ? (stop - start) : 0 }
    user { assignation.user }

    trait :running do
      start { Time.current - 1.minute }
    end

    trait :stopped do
      start { Time.current - 2.minutes }
      stop { Time.current - 1.minute }
    end
  end

  factory :assignee, class: "Decidim::TimeTracker::Assignee" do
    user
  end

  factory :tos_acceptance, class: "Decidim::TimeTracker::TosAcceptance" do
    assignee
    time_tracker
  end
end
