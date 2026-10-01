# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe RefreshCertificationsJob do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:activity) { create(:activity, task:, active: true) }
    let(:skill) { create(:skill, organization:, tasks: [task], required_completions_per_activity: 2) }

    before do
      create(:assignation, :completed, activity:, user:)
      skill
    end

    it "certifies a participant who already qualifies under the current rules" do
      skill.update!(required_completions_per_activity: 1)

      expect { described_class.perform_now(task) }.to change(SkillCertification, :count).by(1)
    end

    it "revokes a certification the participant no longer qualifies for" do
      skill.update!(required_completions_per_activity: 1)
      described_class.perform_now(task)

      skill.update!(required_completions_per_activity: 5)

      expect { described_class.perform_now(task) }.to change(SkillCertification, :count).by(-1)
    end

    it "reaches participants who are certified but no longer assigned" do
      skill.update!(required_completions_per_activity: 1)
      described_class.perform_now(task)
      Assignation.where(user:).destroy_all

      expect { described_class.perform_now(task) }.to change(SkillCertification, :count).by(-1)
    end

    it "does nothing when the task has gone away" do
      expect { described_class.perform_now(nil) }.not_to raise_error
    end
  end
end
