# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe CheckoutSurveyStats do
    subject { described_class.new(time_tracker) }

    let(:organization) { create(:organization) }
    let(:time_tracker) { create(:time_tracker, component: create(:time_tracker_component, participatory_space: create(:participatory_process, organization:))) }
    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:) }

    def answer_by(user, **attributes)
      assignation = create(:assignation, user:, activity:)
      event = create(:time_event, :stopped, assignation:, activity:, user:)
      create(:checkout_response, time_event: event, **attributes)
    end

    it "averages the scales and counts people" do
      2.times { answer_by(create(:user, organization:), work_nature: 1, work_value: 4, usually_paid: "no") }
      answer_by(create(:user, organization:), work_nature: 4, work_value: 2, usually_paid: "yes")

      expect(subject.overall).to have_attributes(people: 3, responses: 3, avg_nature: 2.0, avg_value: 3.3, unpaid_share: 67)
      expect(subject.involved_counts["creating"]).to eq(3)
    end

    it "ignores other time trackers" do
      create(:checkout_response)
      expect(subject).not_to be_any
    end

    describe "demographic groups" do
      before do
        10.times do
          user = create(:user, organization:)
          create(:data_donation, user:, gender_identities: %w(woman), age_range: "18_24")
          answer_by(user)
        end
        3.times do
          user = create(:user, organization:)
          create(:data_donation, user:, gender_identities: %w(non_binary), age_range: "18_24")
          answer_by(user)
        end
      end

      it "hides groups with fewer than 10 people" do
        gender = subject.by_dimension["gender_identities"].index_by(&:label)
        expect(gender["Woman"]).to have_attributes(people: 10, hidden: false)
        expect(gender["Non-binary"]).to have_attributes(people: 3, hidden: true)
        expect(subject.by_dimension["age_range"].first).to have_attributes(people: 13, hidden: false)
      end

      it "leaves hidden groups out of the CSV" do
        csv = subject.to_csv
        expect(csv).to include("gender_identities,Woman,10")
        expect(csv).not_to include("Non-binary")
      end

      it "never uses data from volunteers who did not consent" do
        Decidim::TimeTracker::DataDonation.find_each { |donation| donation.update!(consented: false) if donation.gender_identities == %w(woman) }
        expect(subject.by_dimension["gender_identities"].map(&:label)).to eq(["Non-binary"])
      end
    end
  end
end
