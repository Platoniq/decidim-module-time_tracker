# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Builds a self-contained demonstration of the skills and badges system.
    #
    # It creates its own participatory process so it can be run against a real
    # instance without touching anything already there, and populates it with a
    # cast of participants at deliberately different stages — one who has only
    # just joined, one waiting on admin verification, one certified in a single
    # skill, one holding every skill and maxing out a badge — so that all the
    # states the public pages can render are visible at once.
    #
    # Run it with `rake decidim_time_tracker:demo_seed`. It refuses to run twice
    # unless the caller asks for the previous demo to be replaced.
    class DemoSeeder
      SLUG = "volunteer-skills-demo"

      # Enough to trip the smaller thresholds without needing a huge cast.
      SESSION_SECONDS = 45 * 60

      def initialize(organization: nil, replace: false, logger: nil)
        @organization = organization || Decidim::Organization.first
        @replace = replace
        @logger = logger || ->(message) { puts message }
      end

      def call
        raise "No organization found to seed into" if organization.blank?

        handle_existing_demo

        log "Seeding the skills & badges demo into #{organization.name}…"
        # All or nothing: a failure part-way through would otherwise leave a
        # half-built demo behind on whatever instance this was pointed at.
        ActiveRecord::Base.transaction do
          build_process
          build_component
          build_tasks_and_activities
          build_skills
          build_badges
          build_participants
          certify_everyone
        end

        log_summary
      end

      # Removes everything the demo created, and nothing else: the demo process
      # and its component, the skills and badges tagged "[Demo]", and the demo
      # participants. Certifications and gamification scores unwind through the
      # models' own callbacks.
      def destroy_demo
        raise "No organization found" if organization.blank?

        purge_demo!
        log "Demo removed."
      end

      private

      attr_reader :organization, :replace, :process, :component, :time_tracker, :tasks, :skills, :participants

      def log(message)
        @logger.call(message)
      end

      def admin
        @admin ||= Decidim::User.where(organization:, admin: true).not_deleted.first ||
                   raise("No admin user found in #{organization.name}; the demo needs one to attribute admin actions to")
      end

      def handle_existing_demo
        return unless demo_present?

        raise "A demo already exists (process /processes/#{SLUG} and/or its participants). Re-run with REPLACE=1 to rebuild it." unless replace

        log "Removing the previous demo…"
        purge_demo!
      end

      # Checked across all three homes the demo has, not just the process: an
      # interrupted run can leave participants or skills behind on their own,
      # and those collide on the next attempt.
      def demo_present?
        find_demo_process.present? ||
          demo_users.exists? ||
          demo_skills.exists?
      end

      def demo_users
        Decidim::User.where(organization:).where("email LIKE ?", "demo-volunteer-%@example.org")
      end

      def demo_skills
        Decidim::TimeTracker::Skill.where(organization:).where("name->>'en' LIKE ?", "[Demo]%")
      end

      # Participatory processes are soft-deleted, and a trashed one still holds
      # the slug against the unique index — so the demo has to look past the
      # default scope and hard-delete, or a rebuild collides with its own
      # leftovers.
      def find_demo_process
        Decidim::ParticipatoryProcess.with_deleted.find_by(organization:, slug: SLUG)
      end

      # Removes the demo in dependency order, deepest first.
      #
      # None of this can be left to cascades: destroying a participatory space
      # does not reach into the time tracker's tables, and time events and
      # milestones hold foreign keys straight to decidim_users, so anything
      # skipped here surfaces later as a foreign key violation.
      def purge_demo!
        Decidim::TimeTracker::TimeEvent.where(user: demo_users).delete_all
        Decidim::TimeTracker::Milestone.where(user: demo_users).destroy_all
        Decidim::TimeTracker::ActivityCompletion
          .joins(:assignation)
          .where(decidim_time_tracker_assignations: { decidim_user_id: demo_users.select(:id) })
          .destroy_all
        # Destroyed rather than deleted so the gamification score unwinds.
        Decidim::TimeTracker::SkillCertification.where(user: demo_users).destroy_all
        Decidim::TimeTracker::Assignation.where(user: demo_users).destroy_all

        assignees = Decidim::TimeTracker::Assignee.where(user: demo_users)
        Decidim::TimeTracker::TosAcceptance.where(assignee: assignees).destroy_all
        assignees.destroy_all

        destroy_demo_tasks
        # Skills and badges belong to the organization, not to the process, so
        # they are matched by the "[Demo]" prefix the seed gives them.
        Decidim::TimeTracker::Badge.where(organization:).where("name->>'en' LIKE ?", "[Demo]%").destroy_all
        demo_skills.destroy_all

        demo_users.find_each(&:destroy!)
        find_demo_process&.really_destroy!
      end

      def destroy_demo_tasks
        existing = find_demo_process
        return if existing.blank?

        components = Decidim::Component.where(participatory_space: existing, manifest_name: "time_tracker")
        trackers = Decidim::TimeTracker::TimeTracker.where(component: components)

        Decidim::TimeTracker::Task.where(time_tracker: trackers).destroy_all
        trackers.destroy_all
      end

      def build_process
        @process = Decidim::ParticipatoryProcess.create!(
          organization:,
          slug: SLUG,
          title: localized("[Demo] Neighbourhood volunteer programme"),
          subtitle: localized("Seeing how skills and badges are earned"),
          short_description: localized("<p>A worked example of the time tracker's skills and badges.</p>"),
          description: localized(
            "<p>This process exists to demonstrate how volunteers earn skills and badges by tracking " \
            "their time and having their work verified by an administrator.</p>"
          ),
          published_at: Time.current
        )
        log "  process: /processes/#{SLUG}"
      end

      def build_component
        @component = Decidim::Component.create!(
          participatory_space: process,
          manifest_name: :time_tracker,
          name: localized("Volunteer work"),
          published_at: Time.current
        )

        @time_tracker = Decidim::TimeTracker::TimeTracker.create!(
          component:,
          questionnaire: Decidim::Forms::Questionnaire.new(
            tos: localized("I agree to take part in this volunteer programme."),
            title: localized("Before you start"),
            description: localized("A couple of questions so we know who is volunteering.")
          )
        )

        Decidim::TimeTracker::AssigneeData.create!(
          time_tracker:,
          questionnaire: Decidim::Forms::Questionnaire.new(
            tos: localized("I agree to take part in this volunteer programme."),
            title: localized("About you"),
            description: localized("Optional background questions.")
          )
        )
      end

      # Two tasks: one that certifies skills through completed activities, one
      # that certifies through hours tracked, so both earning modes are shown.
      def build_tasks_and_activities
        @tasks = {}

        @tasks[:garden] = create_task("Community garden", [
                                        "Prepare the raised beds",
                                        "Plant the spring vegetables",
                                        "Run the Saturday watering shift"
                                      ])

        @tasks[:kitchen] = create_task("Community kitchen", [
                                         "Cook the Wednesday meal",
                                         "Serve and clear up"
                                       ])
      end

      def create_task(name, activity_descriptions)
        task = Decidim.traceability.create!(
          Decidim::TimeTracker::Task,
          admin,
          name: localized("[Demo] #{name}"),
          time_tracker:
        )

        activity_descriptions.each_with_index do |description, index|
          Decidim.traceability.create!(
            Decidim::TimeTracker::Activity,
            admin,
            task:,
            description: localized(description),
            active: true,
            weight: index,
            start_date: 1.month.ago,
            end_date: 1.month.from_now,
            requests_start_at: 1.month.ago,
            max_minutes_per_day: 120,
            # One qualifying session of 30 minutes or more files a completion
            # for an admin to verify.
            min_events: 1,
            min_duration_minutes_per_event: 30
          )
        end

        task
      end

      def build_skills
        @skills = {}

        @skills[:growing] = create_skill(
          "Growing food",
          "Preparing beds, planting and keeping a plot watered.",
          tasks: [tasks[:garden]],
          earning_mode: "completed_activities",
          required_activities_count: 2,
          required_completions_per_activity: 1
        )

        @skills[:reliability] = create_skill(
          "Reliable shift work",
          "Turning up week after week — earned on hours tracked, not on finishing anything.",
          tasks: [tasks[:garden]],
          earning_mode: "time_spent",
          required_minutes: 6 * 60
        )

        @skills[:catering] = create_skill(
          "Cooking for a crowd",
          "Cooking and serving a meal for the neighbourhood.",
          tasks: [tasks[:kitchen]],
          earning_mode: "completed_activities",
          required_activities_count: nil, # every activity of the task
          required_completions_per_activity: 1
        )
      end

      def create_skill(name, description, tasks:, **rules)
        Decidim.traceability.create!(
          Decidim::TimeTracker::Skill,
          admin,
          organization:,
          name: localized("[Demo] #{name}"),
          description: localized(description),
          tasks:,
          required_completions_per_activity: 1,
          **rules
        )
      end

      # Four badges covering every metric a badge can be built on, including
      # one earned by holding specific skills — the case where a single badge
      # can be set to need one skill or several.
      def build_badges
        create_badge(
          "Volunteer",
          "Levels up with every piece of work an administrator verifies.",
          metric: "completed_activities",
          levels: [1, 3, 5, 10],
          weight: 0
        )

        create_badge(
          "All-rounder",
          "Earned by being certified in both of the garden skills — one skill gets you to level 1, both to level 2.",
          metric: "required_skills",
          levels: [1, 2],
          skills: [skills[:growing], skills[:reliability]],
          weight: 1
        )

        create_badge(
          "Kitchen hand",
          "A badge that needs a single skill.",
          metric: "required_skills",
          levels: [1],
          skills: [skills[:catering]],
          weight: 2
        )

        create_badge(
          "Time given",
          "Counts the hours tracked across every task.",
          metric: "time_dedicated_hours",
          levels: [1, 3, 8],
          weight: 3
        )

        create_badge(
          "Chronicler",
          "For posting milestones about the work.",
          metric: "milestones_created",
          levels: [1, 3],
          weight: 4
        )
      end

      def create_badge(name, description, skills: [], **attributes)
        Decidim.traceability.create!(
          Decidim::TimeTracker::Badge,
          admin,
          organization:,
          name: localized("[Demo] #{name}"),
          description: localized(description),
          skills:,
          active: true,
          **attributes
        )
      end

      # The cast. `sessions` is how many 45-minute sessions the participant
      # tracked on each activity of the task and `verified` how many of those
      # an admin signed off, which between them place each participant at a
      # different point in the journey. A nil task means they never joined it.
      def participant_plan
        [
          { name: "Ada Newcomer", story: "accepted, has not tracked anything yet",
            garden: { sessions: 0, verified: 0 }, kitchen: nil, milestones: 0 },
          { name: "Ben Waiting", story: "tracked time, still waiting on verification — no skills yet",
            garden: { sessions: 1, verified: 0 }, kitchen: nil, milestones: 1 },
          { name: "Carla Grower", story: "certified in Growing food",
            garden: { sessions: 2, verified: 2 }, kitchen: nil, milestones: 1 },
          { name: "Dan Regular", story: "Growing food plus Reliable shift work, so All-rounder is maxed",
            garden: { sessions: 3, verified: 3 }, kitchen: nil, milestones: 2 },
          { name: "Eva Everything", story: "all three skills, every badge earned",
            garden: { sessions: 3, verified: 3 }, kitchen: { sessions: 2, verified: 2 }, milestones: 4 }
        ]
      end

      def build_participants
        @participants = participant_plan.each_with_index.map do |plan, index|
          user = create_user(plan[:name], index + 1)
          accept_tos(user)

          record_work(user, tasks[:garden], plan[:garden], plan[:milestones])
          record_work(user, tasks[:kitchen], plan[:kitchen], 0)

          plan.merge(user:)
        end
      end

      def create_user(name, index)
        email = "demo-volunteer-#{index}@example.org"

        Decidim::User.create!(
          organization:,
          name:,
          nickname: "demo_volunteer_#{index}",
          email:,
          password: SecureRandom.hex(16),
          confirmed_at: Time.current,
          tos_agreement: true,
          accepted_tos_version: organization.tos_version || Time.current,
          locale: organization.default_locale
        )
      end

      def accept_tos(user)
        assignee = Decidim::TimeTracker::Assignee.create!(user:)
        Decidim::TimeTracker::TosAcceptance.create!(assignee:, time_tracker:)
      end

      # Records the participant's work on a task: an accepted assignation on
      # each activity, `sessions` tracked sessions on each, of which `verified`
      # are signed off by the admin. Completions are written directly rather
      # than through the timer so the seed does not depend on wall-clock
      # behaviour. A nil plan means the participant never joined this task.
      def record_work(user, task, plan, milestones)
        return if plan.blank?

        sessions = plan[:sessions]
        verified = plan[:verified]

        task.activities.each do |activity|
          assignation = Decidim::TimeTracker::Assignation.create!(
            activity:,
            user:,
            status: :accepted,
            invited_at: 3.weeks.ago,
            invited_by_user: admin
          )

          sessions.times do |session|
            started = (3.weeks.ago + (session * 2).days).to_i
            Decidim::TimeTracker::TimeEvent.create!(
              assignation:,
              activity:,
              user:,
              start: started,
              stop: started + SESSION_SECONDS,
              total_seconds: SESSION_SECONDS
            )
          end

          sessions.times do |session|
            completion = Decidim::TimeTracker::ActivityCompletion.create!(
              assignation:,
              requested_at: (3.weeks.ago + (session * 2).days + 1.hour)
            )

            next unless session < verified

            completion.update!(verified_at: 2.weeks.ago, verified_by: admin)
          end

          assignation.sync_completed_at!
        end

        create_milestones(user, task, milestones)
        sync_activity_badge(user)
      end

      def create_milestones(user, task, count)
        count.times do |index|
          Decidim::TimeTracker::Milestone.create!(
            user:,
            activity: task.activities.first,
            title: "Week #{index + 1}: #{task.activities.first.description["en"]}",
            description: "A short note about what got done this week."
          )
        end
      end

      # Mirrors what VerifyCompletion does for the core gamification badge.
      def sync_activity_badge(user)
        verified = Decidim::TimeTracker::ActivityCompletion.verified
                                                           .joins(:assignation)
                                                           .where(decidim_time_tracker_assignations: { decidim_user_id: user.id })
                                                           .count

        Decidim::Gamification.set_score(user, :time_tracker_activities, verified)
      end

      # Certifications are normally awarded as completions are verified; the
      # seed writes the completions directly, so it runs the certifier itself.
      def certify_everyone
        participants.each do |participant|
          tasks.each_value do |task|
            Decidim::TimeTracker::SkillCertifier.new(participant[:user], task).refresh
          end
        end
      end

      def log_summary
        log ""
        log "Done. #{Decidim::TimeTracker::Skill.where(organization:).count} skills, " \
            "#{Decidim::TimeTracker::Badge.where(organization:).count} badges."
        log ""
        log "Participants (password reset needed to sign in as them):"

        participants.each do |participant|
          user = participant[:user]
          certified = Decidim::TimeTracker::SkillCertification.where(user:).count
          log "  #{user.nickname.ljust(18)}#{user.email.ljust(30)}#{certified} skill(s) — #{participant[:story]}"
        end

        log ""
        log "Public pages: /badges (the explainer) and /my_voluntary_work (per participant)"
      end

      def localized(text)
        organization.available_locales.index_with { text }
      end
    end
  end
end
