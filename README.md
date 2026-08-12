# Decidim::TimeTracker

[![Lint](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/lint.yml/badge.svg)](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/lint.yml)
[![Unit Tests](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/unit_tests.yml/badge.svg)](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/unit_tests.yml)
[![Integration Tests](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/system_tests.yml/badge.svg)](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/system_tests.yml)
[![Admin Questionnaire Tests](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/system_questionnaire_tests.yml/badge.svg)](https://github.com/Platoniq/decidim-module-time_tracker/actions/workflows/system_questionnaire_tests.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/9372a7def91c50d04e8c/maintainability)](https://codeclimate.com/github/Platoniq/decidim-module-time_tracker/maintainability)
[![Coverage Status](https://coveralls.io/repos/github/Platoniq/decidim-module-time_tracker/badge.svg?branch=main)](https://coveralls.io/github/Platoniq/decidim-module-time_tracker?branch=main)

A tool for Decidim that records the time volunteers spend on organised work, and
turns that record into recognition: verified work certifies **skills**, and
skills, hours and milestones raise **badges**.

## Usage

Time Tracker is a Component you add to a participatory space. Inside it you
create **tasks**, and each task holds **activities** that volunteers apply to,
are accepted onto, and then track their time against.

Time alone does not earn anything. The chain is:

1. **Join an activity.** The volunteer applies; an administrator accepts or rejects.
2. **Track time.** A play / pause / stop timer, and an optional milestone (title,
   description, photo) when a session ends.
3. **An administrator verifies.** Meeting an activity's completion rule files a
   request. Until an administrator verifies it, it counts for nothing.
4. **A skill is certified.** Enough verified work on a task certifies the skills
   attached to that task.
5. **Badges level up**, automatically, from verified completions, certified
   skills, hours tracked or milestones posted.

### Skills

A **skill** is a competence the organisation certifies. Skills belong to the
organisation, not to a component, so one definition is shared by every Time
Tracker on the platform. A skill is attached to one or more tasks and earned in
one of two ways:

- **completed activities** — complete a number of the task's activities (or all
  of them), each verified a set number of times;
- **time spent** — track a total number of hours across the task's activities.
  Note that this mode reads raw tracked time and does **not** require admin
  verification.

> **Attach skills to your tasks.** A task with no skill still certifies
> something: the module falls back to certifying the task itself, using the
> *task name* as the name of the competence. A volunteer's profile then reads
> "Performance Play #2 (tech + cleanup)" instead of "Stage production". Group
> several related tasks under one skill and the profile says something a person
> could put on a CV.

### Badges

A **badge** is a levelled award over a single metric. Administrators choose what
it counts and how many levels it has; the threshold for each level is prefilled
from a curve suited to the metric and stays editable.

| Metric | Counts |
| --- | --- |
| `completed_activities` | Activity completions an administrator verified |
| `skills_earned` | Distinct skills certified |
| `required_skills` | How many of the badge's own named skills are certified |
| `time_dedicated_hours` | Hours tracked |
| `milestones_created` | Milestones posted |

A badge can be restricted to specific tasks, or count across every task.

The `required_skills` metric is how you build "earned by one skill **or**
several": name the skills, then let the level thresholds decide. Levels `1`
means any one of them earns the badge; levels `1, 2, 3` over three skills means
one earns level 1 and all three earn level 3.

### Public pages

| Path | What it shows |
| --- | --- |
| `/badges` | The public explainer: every skill the organisation can certify with its earning rule in plain words, every badge with its thresholds, and where the signed-in participant stands. Replaces Decidim's core gamification page, which can only describe badges registered in code. |
| `/my_voluntary_work` | The participant's own record across every Time Tracker component: time per activity, badge progress and dated skill certifications. |

`/gamification/badges` redirects to `/badges`.

## Trying it out

The module ships a seed that builds a complete worked example — a youth-led
theatre season with sixteen tasks in six strands, seven skills, seven badges and
ten volunteers placed from "just joined" to "every badge earned", so every state
the public pages can render is visible at once.

It creates its own participatory space and tags everything it makes, so it is
safe to point at a running instance.

```bash
bundle exec rails decidim_time_tracker:demo_seed
bundle exec rails decidim_time_tracker:demo_seed REPLACE=1   # rebuild it
bundle exec rails decidim_time_tracker:demo_unseed           # remove it
```

Pass `ORGANIZATION_HOST=…` to target a specific organization; otherwise the
first one is used.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "decidim-time_tracker", git: "https://github.com/Platoniq/decidim-module-time_tracker"
```

And then execute:

```bash
bundle
bundle exec rails decidim_time_tracker:webpacker:install
bundle exec rails decidim_time_tracker:install:migrations
bundle exec rails db:migrate
```

## About Time tracker and attached questionnaires

By default, every time tracker component has an attached questionnaire for the volunteer to fill with their personal data and to give their consent to the T&C (further referenced as **questionnaire for assignees**). Activities have also an attached questionnaire for the volunteer to fill when they request to be assigned to that activity (further referenced as **questionnaire for activities**). This is a very simple questionnaire with questions about how certain tasks may usually be perceived as related to certain genders. This can be useful to have a better understanding of the perception of tasks and their real gender assignation.

Both questionnaires are enabled by default and can be customized. You may also disable the questionnaire shown for activities. However, take into account that administrators can always modify or create custom questionnaires.

If you want to customize the default questionnaires or disable the questionnaire for activities, just create a new initializer in `config/initializers/time_tracker.rb` with the following content:

**To use your own questionnaire for _assignees_** (use [config/default_assignee_questionnaire.yml](config/default_assignee_questionnaire.yml) as an example guide):
```ruby
# config/initializers/time_tracker.rb

# Initialize my custom questionnaire placed in config/my_questionnaire.yml
Decidim::TimeTracker.configure do |config|
  config.default_assignee_questionnaire_seeds = YAML.load_file File.join(Rails.root, 'config', 'my_assignee_questionnaire.yml')
end
```

**To use your own questionnaire for _activities_** (use [config/default_activity_questionnaire.yml](config/default_activity_questionnaire.yml) as an example guide):
```ruby
# config/initializers/time_tracker.rb

# Initialize my custom questionnaire placed in config/my_questionnaire.yml
Decidim::TimeTracker.configure do |config|
  config.default_activity_questionnaire_seeds = YAML.load_file File.join(Rails.root, 'config', 'my_activities_questionnaire.yml')
end
```

**To completely disable the default questionnaire for _activities_**:
```ruby
# config/initializers/time_tracker.rb

# Disable the default questionnaire for time tracker
Decidim::TimeTracker.configure do |config|
  config.default_activity_questionnaire_seeds = nil
end
```

> **NOTE:** If you customize your questionnaires, you can use any I18n key to translate it. Just add it to your locales.
> You also can just put a direct text with no translations, then it will be used for all languages.

## Contributing

See [Decidim](https://github.com/decidim/decidim).

### Developing

To start contributing to this project, first:

- Install the basic dependencies (such as Ruby and PostgreSQL)
- Clone this repository

Decidim's main repository also provides a Docker configuration file if you
prefer to use Docker instead of installing the dependencies locally on your
machine.

You can create the development app by running the following commands after
cloning this project:

```bash
bundle
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake development_app
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

Then to test how the module works in Decidim, start the development server:

```bash
cd development_app
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rails s
```

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add the environment variables to the root directory of the project in a file
named `.rbenv-vars`. If these are defined for the environment, you can omit
defining these in the commands shown above.

#### Code Styling

Please follow the code styling defined by the different linters that ensure we
are all talking with the same language collaborating on the same project. This
project is set to follow the same rules that Decidim itself follows.

[Rubocop](https://rubocop.readthedocs.io/) linter is used for the Ruby language.

You can run the code styling checks by running the following commands from the
console:

```
bundle exec rubocop
```

To ease up following the style guide, you should install the plugin to your
favorite editor, such as:

- Atom - [linter-rubocop](https://atom.io/packages/linter-rubocop)
- Sublime Text - [Sublime RuboCop](https://github.com/pderichs/sublime_rubocop)
- Visual Studio Code - [Rubocop for Visual Studio Code](https://github.com/misogi/vscode-ruby-rubocop)

### Testing

To run the tests run the following in the gem development path:

```bash
bundle
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake test_app
DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rspec
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add these environment variables to the root directory of the project in a
file named `.rbenv-vars`. In this case, you can omit defining these in the
commands shown above.

### Test code coverage

If you want to generate the code coverage report for the tests, you can use
the `SIMPLECOV=1` environment variable in the rspec command as follows:

```bash
SIMPLECOV=1 bundle exec rspec
```

This will generate a folder named `coverage` in the project root which contains
the code coverage report.

### Localization

If you would like to see this module in your own language, you can help with its
translation at Crowdin:

https://crowdin.com/project/decidim-module-time_tracker

## License

This engine is distributed under the GNU AFFERO GENERAL PUBLIC LICENSE.
