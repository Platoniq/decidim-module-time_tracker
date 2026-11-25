# frozen_string_literal: true

module Decidim
  module TimeTracker
    # Totals of the check-out survey for one time tracker, for the admin stats
    # page and its CSV. Never lists people: answers are averaged, and any
    # demographic group with fewer than DataDonation::MIN_GROUP people is hidden.
    class CheckoutSurveyStats
      DIMENSIONS = %w(gender_identities age_range disability migrant_background).freeze

      Row = Struct.new(:label, :people, :responses, :avg_nature, :avg_value, :unpaid_share, :hidden, keyword_init: true)

      def initialize(time_tracker)
        @time_tracker = time_tracker
      end

      def responses
        @responses ||= CheckoutResponse.for_time_tracker(@time_tracker).includes(activity: :task).to_a
      end

      def any?
        responses.any?
      end

      def overall
        row_for(I18n.t("decidim.time_tracker.admin.stats.checkout.everyone"), responses)
      end

      def involved_counts
        CheckoutResponse::INVOLVED.index_with { |key| responses.count { |response| response.involved.include?(key) } }
      end

      def paid_counts
        CheckoutResponse::USUALLY_PAID.index_with { |key| responses.count { |response| response.usually_paid == key } }
      end

      def by_task
        responses.group_by { |response| response.activity.task }.map do |task, task_responses|
          row_for(translated(task.name), task_responses)
        end
      end

      def donated_people
        donations.size
      end

      # { dimension => [Row, ...] }, groups under the minimum size marked hidden.
      def by_dimension
        DIMENSIONS.index_with do |dimension|
          groups = Hash.new { |hash, key| hash[key] = [] }
          responses.each do |response|
            donation = donations[response.decidim_user_id]
            next unless donation

            Array(donation.public_send(dimension)).compact_blank.each { |value| groups[value] << response }
          end
          rows = groups.map do |value, group_responses|
            row = row_for(group_label(dimension, value), group_responses)
            row.hidden = row.people < DataDonation::MIN_GROUP
            row
          end
          rows.sort_by { |row| -row.people }
        end
      end

      def to_csv
        require "csv"
        CSV.generate do |csv|
          csv << %w(section group people responses avg_intellectual_1_to_physical_5 avg_non_productive_1_to_productive_5 share_usually_unpaid)
          csv << csv_row("overall", overall)
          by_task.each { |row| csv << csv_row("task", row) }
          by_dimension.each do |dimension, rows|
            rows.reject(&:hidden).each { |row| csv << csv_row(dimension, row) }
          end
        end
      end

      private

      def donations
        @donations ||= DataDonation.consented.where(decidim_user_id: responses.map(&:decidim_user_id).uniq).index_by(&:decidim_user_id)
      end

      def row_for(label, group)
        Row.new(
          label:,
          people: group.map(&:decidim_user_id).uniq.size,
          responses: group.size,
          avg_nature: average(group.filter_map(&:work_nature)),
          avg_value: average(group.filter_map(&:work_value)),
          unpaid_share: share(group.count { |response| response.usually_paid == "no" }, group.count { |response| response.usually_paid.present? }),
          hidden: false
        )
      end

      def average(values)
        return nil if values.empty?

        (values.sum.to_f / values.size).round(1)
      end

      def share(part, total)
        return nil if total.zero?

        (100.0 * part / total).round
      end

      def group_label(dimension, value)
        key = dimension == "gender_identities" ? "gender" : dimension
        I18n.t("decidim.time_tracker.time_tracker.checkout_survey.donation.#{key}.#{value}")
      end

      def translated(value)
        value.is_a?(Hash) ? (value[I18n.locale.to_s].presence || value.values.compact_blank.first) : value
      end

      def csv_row(section, row)
        [section, row.label, row.people, row.responses, row.avg_nature, row.avg_value, row.unpaid_share]
      end
    end
  end
end
