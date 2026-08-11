# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Turns the skill and badge rules — which are stored as a mode plus a few
    # numeric columns — into the sentences the public explainer page shows
    # participants. Admins configure thresholds; participants need to read
    # what they have to actually go and do.
    module BadgesHelper
      include Decidim::TranslatableAttributes

      SCOPE = "decidim.time_tracker.badges.index"

      # What a participant has to do to be certified in this skill.
      def skill_rule_sentence(skill)
        if skill.time_spent?
          t("skill_rules.time_spent", scope: SCOPE, hours: skill_required_hours(skill))
        elsif skill.required_activities_count.present?
          t("skill_rules.completed_activities_some",
            scope: SCOPE,
            activities: skill.required_activities_count,
            count: skill.required_completions_per_activity)
        else
          t("skill_rules.completed_activities_all", scope: SCOPE, count: skill.required_completions_per_activity)
        end
      end

      # Hours read better than the stored minutes, and whole numbers should
      # not be shown as "6.0".
      def skill_required_hours(skill)
        hours = skill.required_minutes.to_i / 60.0
        (hours % 1).zero? ? hours.to_i : hours.round(1)
      end

      # What the badge counts, and over which work.
      def badge_rule_sentence(badge)
        if badge.required_skills?
          t("badge_rules.required_skills", scope: SCOPE, skills: names_list(badge.skills))
        elsif badge.tasks.any?
          t("badge_rules.restricted_to", scope: SCOPE, metric: badge_metric_label(badge), tasks: names_list(badge.tasks))
        else
          t("badge_rules.all_tasks", scope: SCOPE, metric: badge_metric_label(badge))
        end
      end

      # "1 → 3 → 5 → 10", the thresholds for each successive level.
      def badge_levels_sentence(badge)
        badge.levels.join(" → ")
      end

      # The emblem for a badge, chosen from what it counts. Admin-defined
      # badges carry no image of their own, so the metric stands in for one —
      # every badge gets a mark, and two badges counting the same thing look
      # like siblings.
      BADGE_ICONS = {
        "completed_activities" => "trophy-line",
        "skills_earned" => "award-line",
        "required_skills" => "medal-line",
        "time_dedicated_hours" => "timer-line",
        "milestones_created" => "quill-pen-line"
      }.freeze

      def badge_icon_name(badge)
        BADGE_ICONS.fetch(badge.metric, "trophy-line")
      end

      # What the badge counts, in plain words ("hours tracked", "skills
      # certified"), reused inside the rule sentences.
      def badge_metric_label(badge)
        t("counts.#{badge.metric}", scope: SCOPE)
      end

      # The tasks that can certify a skill, labelled with the space they live
      # in so participants can tell two same-named tasks apart.
      def skill_task_labels(skill)
        skill.tasks.map do |task|
          space = task.component&.participatory_space
          name = translated_attribute(task.name)
          space ? "#{name} (#{translated_attribute(space.title)})" : name
        end
      end

      private

      def names_list(records)
        records.map { |record| translated_attribute(record.name) }.to_sentence
      end
    end
  end
end
