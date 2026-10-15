# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Builds a full worked example of the skills and badges system.
    #
    # The programme it seeds — a youth-led legislative theatre season — is
    # deliberately shaped like a real one: sixteen tasks grouped into six
    # strands, where each strand's tasks all certify the same skill. That is
    # the pattern the module is meant to be used with, and the opposite of
    # the common mistake of leaving every task without a skill, which makes
    # each task name become its own "competence" on a volunteer's profile.
    #
    # It creates its own participatory space, so it can be run against a live
    # instance without touching anything already there, and every record it
    # makes is tagged so it can be removed again.
    #
    # Run with `rake decidim_time_tracker:demo_seed`.
    class DemoSeeder
      SLUG = "volunteer-skills-demo"

      # Demo records used to be named with this prefix. Names are clean now,
      # but the teardown still recognises it so a demo left behind by an older
      # version of this seed can be removed.
      LEGACY_TAG = "[Demo]"

      # Tracked sessions average 45 minutes, long enough to satisfy an
      # activity's completion rule on its own, so the arithmetic in the cast
      # below stays readable. They are not all 45, though: lengths come in pairs
      # around it (55/35, 50/40, 60/30, 45/45) within a volunteer's task, so the
      # task totals that skills and badges count are exactly what 45 each gives.
      SESSION_MINUTES = 45
      SESSION_SWINGS = [10, 5, 15, 0].freeze
      # Volunteers track at different times of day.
      SESSION_HOURS = [9, 17, 11, 19, 14, 10, 18, 16].freeze
      # Recent sessions still waiting for an admin, each over the 30-minute bar.
      PENDING_MINUTES = [50, 35, 70, 40, 85, 55, 45, 65].freeze

      # ---------------------------------------------------------------- shape
      #
      # Six strands. Every task in a strand certifies that strand's skill, so
      # a volunteer who works across a strand ends up with one meaningful
      # competence rather than a list of task names.
      STRANDS = {
        facilitation: {
          skill: "Group facilitation",
          skill_description: "Holding a room: opening a session, keeping a group in dialogue and closing well.",
          tasks: {
            "Trust-building workshops" => ["Run the opening circle", "Lead a trust exercise", "Close and debrief"],
            "Experience mapping sessions" => ["Set up the mapping wall", "Facilitate the mapping session"],
            "Moderating deliberation" => ["Prepare the deliberation format", "Moderate the session"]
          }
        },
        performance: {
          skill: "Devising and performance",
          skill_description: "Building scenes from lived experience and performing them to an audience.",
          tasks: {
            "Scene development rehearsals" => ["Devise the opening scene", "Rehearse the forum scene"],
            "Performance: matinee" => ["Warm up and dress run", "Perform the matinee"],
            "Performance: evening show" => ["Warm up and notes", "Perform the evening show"]
          }
        },
        production: {
          skill: "Stage production",
          skill_description: "Making the room work: setup, accessibility, sound and a clean get-out.",
          tasks: {
            "Room setup and accessibility" => ["Lay out the space", "Check step-free access and sightlines"],
            "Stage tech and sound" => ["Rig and sound check", "Operate sound during the show"],
            "Get-out and cleanup" => ["Strike the set", "Return the venue to the caretaker"]
          }
        },
        documentation: {
          skill: "Documentation and media",
          skill_description: "Keeping a record the programme can actually use afterwards.",
          tasks: {
            "Photography and filming" => ["Shoot the rehearsal", "Shoot the performance"],
            "Session note-taking" => ["Take notes in the session", "Write up and circulate"],
            "Social media coverage" => ["Draft the posts", "Publish and respond"]
          }
        },
        wellbeing: {
          skill: "Peer wellbeing support",
          skill_description: "Looking after people working with difficult material, and knowing when to escalate.",
          tasks: {
            "Wellbeing check-ins" => ["Run pre-session check-ins", "Run post-session check-outs"],
            "Peer support during rehearsals" => ["Be on call during rehearsal", "Follow up afterwards"]
          }
        },
        policy: {
          skill: "Policy advocacy",
          skill_description: "Turning what the room surfaced into something a decision-maker can act on.",
          tasks: {
            "Structural injustice analysis" => ["Map the barriers raised", "Test the analysis with the group"],
            "Policy proposal drafting" => ["Draft the proposal", "Redraft with the group's feedback"]
          }
        }
      }.freeze

      # A seventh skill that is not tied to a strand: it rewards showing up
      # over time rather than finishing anything, so the time_spent earning
      # mode is visible in the demo too.
      COMMITMENT_SKILL = {
        name: "Sustained commitment",
        description: "Turning up across the season, whatever the job that week.",
        required_hours: 6,
        strands: [:facilitation, :performance, :production]
      }.freeze

      # The strands above all run across the whole season, so on their own
      # every activity on the page would read "Open". Two more tasks show the
      # other states: an audition that has already happened, and wrap-up work
      # still ahead — one activity already taking requests, one whose requests
      # open later. Offsets are from the moment the seed runs. Nobody has
      # tracked time on these, so they stay consistent with the cast's history.
      TIMED_TASKS = [
        {
          name: "Open auditions",
          strand: :performance,
          activities: [
            { description: "Run the open auditions", requests: -12.weeks, starts: -10.weeks, ends: -3.weeks }
          ]
        },
        {
          name: "Season wrap-up",
          strand: :production,
          activities: [
            { description: "Plan the closing celebration", requests: -1.week, starts: 3.weeks, ends: 5.weeks },
            { description: "Return borrowed equipment", requests: 2.weeks, starts: 6.weeks, ends: 7.weeks }
          ]
        }
      ].freeze

      # How far along each activity is, as an admin would report it, cycled
      # through the strand activities so the page shows a spread of progress.
      PROGRESS_STEPS = [100, 85, 70, 60, 45, 30, 20, 10].freeze

      # Portraits from the avatars Decidim ships for its own seeds, picked to
      # suit each name. A face per volunteer makes the avatar stacks and the
      # people lists read as people rather than as rows of blank discs.
      AVATARS = {
        "Ama Boateng" => "080", "Bilal Haddad" => "033", "Cerys Morgan" => "083",
        "Dmitri Volkov" => "072", "Efua Mensah" => "078", "Farida Aziz" => "046",
        "Gethin Price" => "020", "Halima Yusuf" => "093", "Ivan Petrov" => "040",
        "Jasmine Clarke" => "009", "Sam Organiser" => "088", "Alex Rivera" => "089",
        "Blair Okoye" => "071"
      }.freeze

      # Everything above is built for a realistic-looking programme, where an
      # activity needs half an hour of tracked time before a completion is
      # filed. That is unwatchable on camera, so the video setup below adds a
      # task whose activities complete after a single minute, plus the accounts
      # needed to record the full loop live: an administrator, a volunteer who
      # still has to apply, and one already accepted and ready to press play.
      VIDEO_TASK = "Video walkthrough (1-minute activities)"
      VIDEO_ACTIVITIES = ["Demo activity A", "Demo activity B"].freeze
      VIDEO_SKILL = "Quick demo skill"

      VIDEO_ACCOUNTS = {
        # Names deliberately avoid the word "demo": Decidim rejects a password
        # that resembles the account's own name, and the volunteers share a
        # password with the rest of the cast.
        "demo-admin@example.org" => { name: "Sam Organiser", nickname: "demo_admin", admin: true },
        "demo-user-a@example.org" => { name: "Alex Rivera", nickname: "demo_user_a", admin: false },
        "demo-user-b@example.org" => { name: "Blair Okoye", nickname: "demo_user_b", admin: false }
      }.freeze

      # Every volunteer account shares one known password — the point of the
      # demo is that anyone can sign in as any of them and look around, and
      # randomising them made the cast useless for that. Pass `password:` (the
      # rake task reads DEMO_PASSWORD) to use another one.
      #
      # Decidim refuses a password containing any part of the organization's
      # host, so the default avoids words a host is likely to have ("demo",
      # "decidim", "platform"…); seeding modules.demo.platoniq.net with the
      # previous "InspireDemo2026!" failed on exactly that.
      DEFAULT_PASSWORD = "decidim123456789"

      # The administrator is the exception. A shared password written in a
      # public repository would hand the admin panel of any instance running
      # the demo to whoever read this file, so unless one is given it gets a
      # random password, printed once at the end of the run.
      def initialize(organization: nil, replace: false, logger: nil, password: nil, admin_password: nil)
        @organization = organization || Decidim::Organization.first
        @replace = replace
        @logger = logger || ->(message) { puts message }
        @password = password.presence || DEFAULT_PASSWORD
        @admin_password = admin_password.presence
      end

      def call
        raise "No organization found to seed into" if organization.blank?

        check_passwords!
        handle_existing_demo

        log "Seeding the skills & badges demo into #{organization_name}…"
        # All or nothing: a failure part-way through would otherwise leave a
        # half-built demo behind on whatever instance this was pointed at.
        ActiveRecord::Base.transaction do
          build_process
          build_component
          build_tasks
          build_skills
          build_badges
          build_participants
          certify_everyone
          build_timed_tasks
          build_video_setup
        end

        log_summary
      end

      # Removes everything the demo created, and nothing else.
      def destroy_demo
        raise "No organization found" if organization.blank?

        purge_demo!
        log "Demo removed."
      end

      private

      attr_reader :organization, :replace, :password,
                  :process, :component, :time_tracker, :tasks, :skills, :participants

      def log(message)
        @logger.call(message)
      end

      # Decidim's password rules depend on the organization (its host, for a
      # start), so a password that seeds one instance can be refused by
      # another. Checked before anything is built, so the run stops with the
      # reason instead of failing on the first account.
      def check_passwords!
        { "DEMO_PASSWORD" => password, "DEMO_ADMIN_PASSWORD" => admin_password }.each do |variable, candidate|
          problems = password_problems(candidate)
          next if problems.empty?

          raise ArgumentError, "#{variable} is refused for #{organization.host}: #{problems.to_sentence}. Pass another one."
        end
      end

      def password_problems(candidate, admin: false)
        probe = Decidim::User.new(organization:, name: "Ama Boateng", nickname: "demo_volunteer_1",
                                  email: "demo-volunteer-1@example.org", admin:, password: candidate)
        probe.validate
        probe.errors[:password]
      end

      def admin_password
        @admin_password ||= generated_admin_password
      end

      def generated_admin_password
        loop do
          candidate = SecureRandom.alphanumeric(24)
          return candidate if password_problems(candidate, admin: true).empty?
        end
      end

      def organization_name
        name = organization.name
        return name unless name.is_a?(Hash)

        name["en"].presence || name.values.find(&:present?)
      end

      def admin
        @admin ||= Decidim::User.where(organization:, admin: true).not_deleted.first ||
                   raise("No admin user found in #{organization_name}; the demo needs one to attribute admin actions to")
      end

      # ------------------------------------------------------------- teardown

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
        find_demo_process.present? || demo_users.exists? || demo_skills.exists? || demo_badges.any?
      end

      def demo_users
        # Covers demo-volunteer-N, demo-admin and demo-user-* alike.
        Decidim::User.where(organization:).where("email LIKE ?", "demo-%@example.org")
      end

      # Demo skills are recognised by what they are attached to: every one of
      # them hangs off a task in the demo component. That beats matching on a
      # name prefix, which would have to be visible to participants, and it
      # cannot collide with a real skill that happens to share a name.
      def demo_skills
        tasks = Decidim::TimeTracker::Task.where(time_tracker: demo_trackers)
        attached = Decidim::TimeTracker::TaskSkill.where(task: tasks).select(:decidim_time_tracker_skill_id)

        Decidim::TimeTracker::Skill
          .where(organization:)
          .where("id IN (?) OR name->>'en' LIKE ?", attached, "#{LEGACY_TAG}%")
      end

      def demo_trackers
        process = find_demo_process
        return Decidim::TimeTracker::TimeTracker.none if process.blank?

        Decidim::TimeTracker::TimeTracker.where(
          component: Decidim::Component.where(participatory_space: process, manifest_name: "time_tracker")
        )
      end

      # Badges have no association back to the demo — one that counts hours
      # across every task looks identical to a real one. They are matched on
      # name *and* description together, which the seed controls exactly, so a
      # real badge would have to duplicate both to be caught.
      def demo_badges
        matches = badge_definitions.map { |name, description| [name, description] }

        Decidim::TimeTracker::Badge.where(organization:).select do |badge|
          badge_name = badge.name["en"].to_s
          matches.any? do |name, description|
            (badge_name == name && badge.description["en"] == description) ||
              # Earlier versions of this seed prefixed every name with
              # "[Demo] ". Recognised so a demo seeded by one of those can
              # still be torn down by this one.
              badge_name == "#{LEGACY_TAG} #{name}"
          end
        end
      end

      # Participatory processes are soft-deleted, and a trashed one still holds
      # the slug against the unique index — so the demo has to look past the
      # default scope and hard-delete, or a rebuild collides with its own
      # leftovers.
      def find_demo_process
        Decidim::ParticipatoryProcess.with_deleted.find_by(organization:, slug: SLUG)
      end

      # Removes the demo in dependency order, deepest first. None of this can
      # be left to cascades: destroying a participatory space does not reach
      # into the time tracker's tables, and time events and milestones hold
      # foreign keys straight to decidim_users.
      def purge_demo!
        # Resolved up front: demo_skills finds them through the demo's tasks,
        # which destroy_demo_tasks is about to remove.
        skill_ids = demo_skills.pluck(:id)

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

        # Badges first: a required_skills badge holds a foreign key to the
        # skills it names.
        demo_badges.each(&:destroy!)
        destroy_demo_tasks
        Decidim::TimeTracker::Skill.where(id: skill_ids).destroy_all

        demo_users.find_each(&:destroy!)
        find_demo_process&.really_destroy!
      end

      def destroy_demo_tasks
        existing = find_demo_process
        return if existing.blank?

        components = Decidim::Component.where(participatory_space: existing, manifest_name: "time_tracker")
        trackers = Decidim::TimeTracker::TimeTracker.where(component: components)

        Decidim::TimeTracker::Task.where(time_tracker: trackers).destroy_all

        # AssigneeData keeps a foreign key to the tracker and the association
        # deliberately has no `dependent:`, so it has to go by hand or the
        # tracker cannot be destroyed. Its questionnaire points back at it
        # polymorphically, so that is cleared first.
        assignee_data = Decidim::TimeTracker::AssigneeData.where(time_tracker: trackers)
        Decidim::Forms::Questionnaire.where(
          questionnaire_for_type: "Decidim::TimeTracker::AssigneeData",
          questionnaire_for_id: assignee_data.select(:id)
        ).destroy_all
        assignee_data.destroy_all

        trackers.destroy_all
      end

      # ---------------------------------------------------------------- build

      def build_process
        @process = Decidim::ParticipatoryProcess.create!(
          organization:,
          slug: SLUG,
          title: localized("Community Stage: a youth-led theatre season"),
          subtitle: localized("A worked example of volunteer skills and badges"),
          short_description: localized(
            "<p>A demonstration programme showing how tracked volunteer time becomes certified skills and badges.</p>"
          ),
          description: localized(
            "<p>Every task in this programme belongs to a strand, and every task in a strand certifies the same " \
            "skill. A volunteer who works across the facilitation strand ends up certified in <em>Group " \
            "facilitation</em> — not in three separate task names.</p>" \
            "<p>This process exists to demonstrate the Time Tracker. The people and the work in it are invented.</p>"
          ),
          published_at: Time.current
        )
        attach_core_seed_image(@process, :hero_image, "city.jpeg")
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
            tos: localized("I agree to take part in this programme and to the terms of participation."),
            title: localized("Before you start"),
            description: localized("A couple of questions so we know who is volunteering.")
          )
        )

        Decidim::TimeTracker::AssigneeData.create!(
          time_tracker:,
          questionnaire: Decidim::Forms::Questionnaire.new(
            tos: localized("I agree to take part in this programme and to the terms of participation."),
            title: localized("About you"),
            description: localized("Optional background questions.")
          )
        )
        log "  component: #{component.id}"
      end

      def build_tasks
        @tasks = {}
        weight = 0

        STRANDS.each do |strand_key, strand|
          @tasks[strand_key] = strand[:tasks].map do |task_name, activity_names|
            weight += 1
            create_task(task_name, activity_names, weight)
          end
        end

        log "  tasks: #{@tasks.values.flatten.size} across #{STRANDS.size} strands"
      end

      def create_task(name, activity_names, weight)
        task = Decidim.traceability.create!(
          Decidim::TimeTracker::Task,
          admin,
          name: localized(name),
          time_tracker:,
          weight:
        )

        activity_names.each_with_index do |description, index|
          Decidim.traceability.create!(
            Decidim::TimeTracker::Activity,
            admin,
            task:,
            description: localized(description),
            active: true,
            weight: index,
            progress: PROGRESS_STEPS[((weight * 3) + index) % PROGRESS_STEPS.size],
            start_date: 2.months.ago,
            end_date: 2.months.from_now,
            requests_start_at: 2.months.ago,
            max_minutes_per_day: 180,
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

        STRANDS.each do |strand_key, strand|
          @skills[strand_key] = create_skill(
            strand[:skill],
            strand[:skill_description],
            tasks: tasks[strand_key],
            earning_mode: "completed_activities",
            # Any two activities of any one task in the strand.
            required_activities_count: 2,
            required_completions_per_activity: 1
          )
        end

        @skills[:commitment] = create_skill(
          COMMITMENT_SKILL[:name],
          COMMITMENT_SKILL[:description],
          tasks: COMMITMENT_SKILL[:strands].flat_map { |key| tasks[key] },
          earning_mode: "time_spent",
          required_minutes: COMMITMENT_SKILL[:required_hours] * 60
        )

        log "  skills: #{@skills.size}"
      end

      def create_skill(name, description, tasks:, **rules)
        Decidim.traceability.create!(
          Decidim::TimeTracker::Skill,
          admin,
          organization:,
          name: localized(name),
          description: localized(description),
          tasks:,
          required_completions_per_activity: 1,
          **rules
        )
      end

      # Badges are built so that each one answers a different question about a
      # volunteer: did they start, did they go deep in one craft, did they
      # spread across the programme, did they keep showing up.
      #
      # Held as data rather than a run of create_badge calls because the
      # teardown needs the same name/description pairs to recognise them again.
      def badge_definitions
        [
          ["Getting started",
           "The first pieces of work an administrator signs off.",
           { metric: "completed_activities", levels: [1, 5, 20], weight: 0 }],

          ["Company member",
           "Awarded for the three crafts that put a show on: facilitation, performance and production. " \
           "One of them earns level 1; all three earn level 3.",
           { metric: "required_skills", levels: [1, 2, 3], weight: 1, skill_keys: [:facilitation, :performance, :production] }],

          ["Care team",
           "For the people who look after everyone else.",
           { metric: "required_skills", levels: [1], weight: 2, skill_keys: [:wellbeing] }],

          ["Policy voice",
           "For turning what the room surfaced into a proposal.",
           { metric: "required_skills", levels: [1], weight: 3, skill_keys: [:policy] }],

          ["All-rounder",
           "Counts every skill certified anywhere in the programme.",
           { metric: "skills_earned", levels: [1, 3, 5], weight: 4 }],

          ["Hours on the floor",
           "Time tracked across the whole season.",
           { metric: "time_dedicated_hours", levels: [2, 6, 15], weight: 5 }],

          ["Chronicler",
           "For leaving a record of the work behind.",
           { metric: "milestones_created", levels: [1, 4, 8], weight: 6 }]
        ]
      end

      def build_badges
        badge_definitions.each do |name, description, attributes|
          attributes = attributes.dup
          skill_keys = attributes.delete(:skill_keys) || []

          create_badge(name, description, skills: skill_keys.map { |key| skills.fetch(key) }, **attributes)
        end

        log "  badges: #{demo_badges.size}"
      end

      def create_badge(name, description, skills: [], **attributes)
        Decidim.traceability.create!(
          Decidim::TimeTracker::Badge,
          admin,
          organization:,
          name: localized(name),
          description: localized(description),
          skills:,
          active: true,
          **attributes
        )
      end

      # ----------------------------------------------------------------- cast
      #
      # Ten volunteers spread deliberately across the states the public pages
      # can render: nobody, waiting on an admin, one craft, several crafts,
      # and everything. `work` maps a strand to how many sessions were tracked
      # on each of its tasks' activities and how many an admin verified, plus
      # `pending`: recent sessions on that strand an admin has yet to verify,
      # so the verification queue holds several people's work, not one.
      def participant_plan
        [
          { name: "Ama Boateng", story: "accepted onto facilitation, has not started the timer",
            work: { facilitation: { sessions: 0, verified: 0 } }, milestones: 0 },

          { name: "Bilal Haddad", story: "tracked two sessions, nothing verified yet — no skills",
            work: { production: { sessions: 0, verified: 0, pending: 2 } }, milestones: 1 },

          { name: "Cerys Morgan", story: "certified in Group facilitation",
            work: { facilitation: { sessions: 2, verified: 2, pending: 1 } }, milestones: 2 },

          { name: "Dmitri Volkov", story: "certified in Devising and performance",
            work: { performance: { sessions: 2, verified: 2, pending: 2 } }, milestones: 1 },

          { name: "Efua Mensah", story: "certified in Stage production",
            work: { production: { sessions: 2, verified: 2, pending: 1 } }, milestones: 3 },

          { name: "Farida Aziz", story: "Documentation and media, and the most milestones posted",
            work: { documentation: { sessions: 3, verified: 3, pending: 2 } }, milestones: 9 },

          { name: "Gethin Price", story: "Peer wellbeing support — earns Care team",
            work: { wellbeing: { sessions: 2, verified: 2, pending: 1 } }, milestones: 1 },

          { name: "Halima Yusuf", story: "Policy advocacy — earns Policy voice",
            work: { policy: { sessions: 2, verified: 2, pending: 1 } }, milestones: 2 },

          { name: "Ivan Petrov", story: "facilitation and performance — Company member level 2",
            work: { facilitation: { sessions: 2, verified: 2 }, performance: { sessions: 2, verified: 2, pending: 1 } },
            milestones: 3 },

          { name: "Jasmine Clarke", story: "all three show crafts plus the hours — Company member maxed",
            work: {
              facilitation: { sessions: 3, verified: 3 },
              performance: { sessions: 3, verified: 3 },
              production: { sessions: 3, verified: 3 },
              documentation: { sessions: 2, verified: 2, pending: 1 }
            },
            milestones: 5 }
        ]
      end

      MILESTONE_NOTES = [
        "Twelve people in the circle today, and everyone spoke at least once.",
        "The forum scene finally landed — the audience stopped the action twice.",
        "Step-free route re-checked after the venue moved the staging.",
        "Sound levels set for the matinee; noted the levels for the evening.",
        "Wrote up the barriers the group named, ready for the drafting session.",
        "Two check-ins today; one person needed a longer conversation afterwards.",
        "Photographed the rehearsal without putting anyone on camera who asked not to be.",
        "Redrafted the proposal with the group's changes to section two.",
        "Get-out finished ahead of time, venue signed off by the caretaker."
      ].freeze

      def build_participants
        @participants = participant_plan.each_with_index.map do |plan, index|
          user = create_user(plan[:name], index + 1)
          accept_tos(user)

          plan[:work].each do |strand_key, shape|
            tasks.fetch(strand_key).each { |task| record_work(user, task, shape) }
            record_pending(user, tasks.fetch(strand_key), shape[:pending].to_i)
          end

          create_milestones(user, plan)
          sync_activity_badge(user)

          plan.merge(user:)
        end
      end

      def create_user(name, index)
        user = Decidim::User.create!(
          organization:,
          name:,
          nickname: "demo_volunteer_#{index}",
          email: "demo-volunteer-#{index}@example.org",
          password:,
          password_confirmation: password,
          confirmed_at: Time.current,
          # Decidim makes an admin change their password on first sign-in when
          # this is blank (User#needs_password_update?). Mid-demo that means
          # being handed a mandatory password form instead of the admin panel.
          password_updated_at: Time.current,
          tos_agreement: true,
          accepted_tos_version: organization.tos_version || Time.current,
          locale: organization.default_locale
        )
        attach_avatar(user)
        user
      end

      def accept_tos(user)
        assignee = Decidim::TimeTracker::Assignee.create!(user:)
        Decidim::TimeTracker::TosAcceptance.create!(assignee:, time_tracker:)
      end

      # Records the participant's work on a task: an accepted assignation on
      # each activity, `sessions` tracked sessions on each, of which `verified`
      # are signed off by the admin. Completions are written directly rather
      # than through the timer so the seed does not depend on wall-clock
      # behaviour.
      def record_work(user, task, shape)
        sessions = shape[:sessions]
        verified = shape[:verified]
        count = task.activities.size * sessions
        index = 0

        task.activities.each_with_index do |activity, activity_index|
          assignation = Decidim::TimeTracker::Assignation.create!(
            activity:,
            user:,
            status: :accepted,
            invited_at: 6.weeks.ago,
            invited_by_user: admin
          )

          sessions.times do |session|
            started = session_start(6.weeks.ago + ((session * 3) + activity_index).days, user, index)
            completion = track_session(assignation, started, session_minutes(index, count))
            completion.update!(verified_at: completion.requested_at + (1 + (index % 3)).days, verified_by: admin) if session < verified
            index += 1
          end

          assignation.sync_completed_at!
        end
      end

      # The k-th of a task's `count` sessions: pairs swing either side of
      # SESSION_MINUTES so the task total stays count × 45.
      def session_minutes(index, count)
        return SESSION_MINUTES if count.odd? && index == count - 1

        swing = SESSION_SWINGS[(index / 2) % SESSION_SWINGS.size]
        index.even? ? SESSION_MINUTES + swing : SESSION_MINUTES - swing
      end

      def session_start(day, user, index)
        hour = SESSION_HOURS[(user.id + index) % SESSION_HOURS.size]
        day.beginning_of_day + hour.hours + ((index % 4) * 15).minutes
      end

      # One tracked session and the completion it files.
      def track_session(assignation, started, minutes)
        Decidim::TimeTracker::TimeEvent.create!(
          assignation:,
          activity: assignation.activity,
          user: assignation.user,
          start: started.to_i,
          stop: started.to_i + (minutes * 60),
          total_seconds: minutes * 60
        )
        Decidim::TimeTracker::ActivityCompletion.create!(
          assignation:,
          requested_at: started + minutes.minutes + (5 + ((assignation.id * 7) % 50)).minutes
        )
      end

      # Recent sessions still waiting for an admin, on different activities of
      # the strand for different volunteers.
      def record_pending(user, strand_tasks, count)
        return if count.zero?

        activities = strand_tasks.flat_map(&:activities)
        activities.rotate(user.id % activities.size).first(count).each do |activity|
          assignation = Decidim::TimeTracker::Assignation.find_by!(activity:, user:)
          @pending_index = (@pending_index || 0) + 1
          day = (1 + ((@pending_index * 5) % 13)).days.ago
          track_session(assignation, session_start(day, user, @pending_index),
                        PENDING_MINUTES[@pending_index % PENDING_MINUTES.size])
          assignation.sync_completed_at!
        end
      end

      # Milestones are attached to activities the volunteer actually worked on.
      def create_milestones(user, plan)
        activities = plan[:work].keys.flat_map { |key| tasks.fetch(key) }.flat_map(&:activities)
        return if activities.empty?

        plan[:milestones].times do |index|
          Decidim::TimeTracker::Milestone.create!(
            user:,
            activity: activities[index % activities.size],
            title: "Week #{index + 1}",
            description: MILESTONE_NOTES[index % MILESTONE_NOTES.size]
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
        all_tasks = tasks.values.flatten

        participants.each do |participant|
          all_tasks.each do |task|
            Decidim::TimeTracker::SkillCertifier.new(participant[:user], task).refresh
          end
        end
      end

      # The finished audition and the wrap-up still ahead. Each certifies its
      # strand's skill, like every other task; the audition was attended by the
      # volunteers who went on to perform, who keep it on their list as a
      # finished activity.
      def build_timed_tasks
        weight = tasks.values.flatten.size

        TIMED_TASKS.each do |definition|
          weight += 1
          task = Decidim.traceability.create!(
            Decidim::TimeTracker::Task,
            admin,
            name: localized(definition[:name]),
            time_tracker:,
            weight:
          )

          definition[:activities].each_with_index do |activity, index|
            create_timed_activity(task, activity, index)
          end

          skills.fetch(definition[:strand]).tasks << task
          join_performers(task) if definition[:strand] == :performance
        end

        log "  timed tasks: #{TIMED_TASKS.size} (one finished, one ahead)"
      end

      def create_timed_activity(task, activity, index)
        Decidim.traceability.create!(
          Decidim::TimeTracker::Activity,
          admin,
          task:,
          description: localized(activity[:description]),
          active: true,
          weight: index,
          requests_start_at: Time.current + activity[:requests],
          start_date: Time.current + activity[:starts],
          end_date: Time.current + activity[:ends],
          max_minutes_per_day: 180,
          min_events: 1,
          min_duration_minutes_per_event: 30
        )
      end

      def join_performers(task)
        performers = participants.select { |participant| participant[:work].has_key?(:performance) }

        task.activities.each do |activity|
          performers.each do |participant|
            Decidim::TimeTracker::Assignation.create!(
              activity:, user: participant[:user], status: :accepted,
              invited_at: 11.weeks.ago, invited_by_user: admin
            )
          end
        end
      end

      # The recording setup: a fast task, a skill it certifies, and the three
      # accounts used on camera.
      def build_video_setup
        task = Decidim.traceability.create!(
          Decidim::TimeTracker::Task,
          admin,
          name: localized(VIDEO_TASK),
          time_tracker:,
          weight: 99
        )

        VIDEO_ACTIVITIES.each_with_index do |description, index|
          Decidim.traceability.create!(
            Decidim::TimeTracker::Activity,
            admin,
            task:,
            description: localized(description),
            active: true,
            weight: index,
            start_date: 2.months.ago,
            end_date: 2.months.from_now,
            requests_start_at: 2.months.ago,
            max_minutes_per_day: 180,
            min_events: 1,
            # One minute of tracked time files a completion — short enough to
            # show the whole chain inside a single take.
            min_duration_minutes_per_event: 1
          )
        end

        create_skill(
          VIDEO_SKILL,
          "Certified by finishing one activity of the video walkthrough task. Exists so the full loop can be filmed.",
          tasks: [task],
          earning_mode: "completed_activities",
          required_activities_count: 1,
          required_completions_per_activity: 1
        )

        @video_users = VIDEO_ACCOUNTS.map do |email, attrs|
          account_password = attrs[:admin] ? admin_password : password
          user = Decidim::User.create!(
            organization:,
            name: attrs[:name],
            nickname: attrs[:nickname],
            email:,
            password: account_password,
            password_confirmation: account_password,
            confirmed_at: Time.current,
            password_updated_at: Time.current,
            tos_agreement: true,
            accepted_tos_version: organization.tos_version || Time.current,
            locale: organization.default_locale,
            admin: attrs[:admin],
            # Set so the admin lands in the panel instead of a terms screen.
            admin_terms_accepted_at: (Time.current if attrs[:admin])
          )
          attach_avatar(user)
          accept_tos(user) unless attrs[:admin]
          user
        end

        # Blair starts already accepted, so a take can begin at "press play"
        # without waiting on an approval. Alex is left with nothing, so the
        # apply-and-accept step can be filmed from the beginning.
        blair = @video_users.find { |u| u.nickname == "demo_user_b" }
        task.activities.each do |activity|
          Decidim::TimeTracker::Assignation.create!(
            activity:, user: blair, status: :accepted,
            invited_at: 1.week.ago, invited_by_user: admin
          )
        end

        log "  video setup: 1 fast task, 1 skill, #{@video_users.size} accounts"
      end

      def log_summary
        log ""
        log "Done. #{demo_skills.count} skills, " \
            "#{demo_badges.size} badges, " \
            "#{tasks.values.flatten.size} tasks."
        log ""
        log "Participants (all volunteer accounts use the password #{password}):"

        participants.each do |participant|
          user = participant[:user]
          certified = Decidim::TimeTracker::SkillCertification
                      .where(user:)
                      .where.not(decidim_time_tracker_skill_id: nil)
                      .distinct
                      .count(:decidim_time_tracker_skill_id)

          log "  #{user.nickname.ljust(18)}#{user.name.ljust(18)}#{certified} skill(s) — #{participant[:story]}"
        end

        log ""
        log "For recording (volunteers: #{password}; administrator: #{admin_password}):"
        (@video_users || []).each do |u|
          role = u.admin? ? "administrator" : "volunteer"
          extra = case u.nickname
                  when "demo_user_a" then " — no assignations yet, film the apply + accept step"
                  when "demo_user_b" then " — already accepted, can press play immediately"
                  else " — builds tasks, skills and badges on camera"
                  end
          log "  #{u.email.ljust(26)}#{role}#{extra}"
        end
        log "  task \"#{VIDEO_TASK}\" completes after 1 minute of tracking"
        log ""
        log "Public pages: /badges (the explainer) and /my_voluntary_work (per participant)"
      end

      def localized(text)
        organization.available_locales.index_with { text }
      end

      def attach_avatar(user)
        number = AVATARS[user.name]
        attach_core_seed_image(user, :avatar, "avatars", "#{number}.jpg") if number
      end

      # Images come from the seed files bundled with decidim-core, so the demo
      # carries none of its own. A missing file just leaves the default
      # placeholder in place.
      def attach_core_seed_image(record, attachment, *path)
        file = Decidim::Core::Engine.root.join("db", "seeds", *path)
        return unless file.exist?

        record.public_send(attachment).attach(io: File.open(file), filename: file.basename.to_s, content_type: "image/jpeg")
      end
    end
  end
end
