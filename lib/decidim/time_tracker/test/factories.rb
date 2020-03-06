# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  factory :time_tracker_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :time_tracker).i18n_name }
    manifest_name { :time_tracker }
    participatory_space { create(:participatory_process, :with_steps) }
  end

  factory :time_tracker, class: "Decidim::TimeTracker::TimeTracker" do
    component { create(:time_tracker_component) }
  end

  factory :activity, class: "Decidim::TimeTracker::Activity" do
    task { create(:task) }
    description { Decidim::Faker::Localized.sentence(3) }
    active { false }
    start_date { 1.day.ago }
    end_date { 1.month.from_now }
    max_minutes_per_day { 60 }
    requests_start_at { Time.zone.today }
  end

  factory :assignee, class: "Decidim::TimeTracker::Assignee" do
    user
    activity { create(:activity) }
    status { :accepted }
    invited_at { 1.month.ago }
    invited_by_user { create(:user) }
    requested_at { 2.months.ago }
    tos_accepted_at { 1.week.ago }

    trait :pending do
      status { :pending }
    end

    trait :active do
      status { :active }
    end

    trait :completed do
      status { :completed }
    end

    trait :suspended do
      status { :suspended }
    end
  end

  factory :milestone, class: "Decidim::TimeTracker::Milestone" do
    time_tracker { create(:time_tracker) }
    user { create(:user) }
    title { Decidim::Faker::Localized.word }
    description { Decidim::Faker::Localized.sentence(3) }
  end

  factory :task, class: "Decidim::TimeTracker::Task" do
    time_tracker { create(:time_tracker) }
    name { Decidim::Faker::Localized.word }
  end

  factory :time_entry, class: "Decidim::TimeTracker::TimeEntry" do
    assignee { create(:assignee) }
    activity { create(:activity) }
    milestone { create(:milestone) }
    time_start { 1.month.ago }
    time_end { 1.month.ago }
    validated_at { Time.zone.today }
    validated_by_user { create(:user) }
  end

  # Add engine factories here
end
