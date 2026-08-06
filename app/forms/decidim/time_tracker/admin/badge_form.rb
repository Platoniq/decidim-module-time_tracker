# frozen_string_literal: true

module Decidim
  module TimeTracker
    module Admin
      # This class holds a Form to create/update badges from Decidim's admin panel.
      class BadgeForm < Decidim::Form
        include TranslatableAttributes

        include TaskSelectable

        mimic :badge

        translatable_attribute :name, String
        translatable_attribute :description, String

        attribute :metric, String
        # How many levels the badge has. The admin picks this from a dropdown;
        # the threshold for each level is prefilled from the metric's default
        # curve, so a badge can be set up without choosing any numbers.
        attribute :levels_count, Integer, default: Decidim::TimeTracker::Badge::DEFAULT_LEVEL_COUNT
        # One threshold per level, in order. Only the first `levels_count` are
        # used — the form always submits every row so switching the dropdown
        # back and forth does not lose what was typed.
        attribute :level_thresholds, [Integer]
        attribute :skill_ids, [Integer]
        attribute :active, Boolean, default: true
        attribute :weight, Integer, default: 0

        validates :name, translatable_presence: true
        validates :metric, inclusion: { in: Decidim::TimeTracker::Badge::METRICS }
        validates :levels_count,
                  numericality: {
                    only_integer: true,
                    greater_than: 0,
                    less_than_or_equal_to: Decidim::TimeTracker::Badge::MAX_LEVELS
                  }
        validate :thresholds_are_ascending_positive_integers
        validates :skill_ids, presence: true, if: ->(form) { form.metric == "required_skills" }

        def map_model(model)
          self.levels_count = model.levels.count
          self.level_thresholds = model.levels
          self.task_ids = model.task_ids
          self.skill_ids = model.skill_ids
        end

        # The thresholds actually stored on the badge: as many as the chosen
        # level count, falling back to the metric's defaults for any level the
        # admin left blank.
        def levels
          @levels ||= begin
            count = (levels_count || Decidim::TimeTracker::Badge::DEFAULT_LEVEL_COUNT)
                    .clamp(1, Decidim::TimeTracker::Badge::MAX_LEVELS)
            defaults = Decidim::TimeTracker::Badge.default_levels(metric, count)

            Array.new(count) do |index|
              submitted = Array(level_thresholds)[index]
              submitted.presence || defaults[index]
            end
          end
        end

        # What each level's field should be prefilled with in the browser,
        # keyed by metric, so the view can hand the whole table to the script.
        def default_curves
          Decidim::TimeTracker::Badge::DEFAULT_LEVEL_CURVES
        end

        def available_skills
          @available_skills ||= Skill.where(organization: current_organization).order(:id)
        end

        def skills
          available_skills.where(id: skill_ids)
        end

        private

        def thresholds_are_ascending_positive_integers
          return if levels.blank?
          return errors.add(:level_thresholds, :invalid) if levels.any?(&:nil?)

          errors.add(:level_thresholds, :invalid) unless levels.all?(&:positive?) && levels == levels.sort && levels == levels.uniq
        end
      end
    end
  end
end
