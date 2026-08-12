# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  describe SkillCertification do
    subject { skill_certification }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:skill_certification) { create(:skill_certification, user:, task:) }

    it { is_expected.to be_valid }

    it "is associated with a user" do
      expect(subject.user).to eq(user)
    end

    it "is associated with a task" do
      expect(subject.task).to eq(task)
    end

    describe "#skill_name" do
      it "returns the task name" do
        expect(subject.skill_name).to eq(task.name)
      end
    end

    context "when the same user is already certified for the same task" do
      before { skill_certification }

      it "is not valid" do
        duplicate = build(:skill_certification, user:, task:)
        expect(duplicate).not_to be_valid
      end
    end

    context "when a different user is certified for the same task" do
      let(:other_user) { create(:user, organization:) }

      it "is valid" do
        other = build(:skill_certification, user: other_user, task:)
        expect(other).to be_valid
      end
    end

    describe "the gamification score" do
      def skill_score
        Decidim::Gamification.status_for(user, :time_tracker_skills).score
      end

      it "goes up when a certification is created" do
        expect { create(:skill_certification, user:, task:) }.to change { skill_score }.by(1)
      end

      it "comes back down when a certification is destroyed" do
        certification = create(:skill_certification, user:, task:)

        expect { certification.destroy! }.to change { skill_score }.by(-1)
      end
    end

    context "when the certified skill is deleted" do
      let(:skill) { create(:skill, organization:, tasks: [task]) }
      let!(:certification) { create(:skill_certification, user:, task:, skill:) }

      it "takes the certification with it rather than raising on the foreign key" do
        expect { skill.destroy! }.to change(described_class, :count).by(-1)
        expect { certification.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "unwinds the gamification score" do
        expect { skill.destroy! }
          .to change { Decidim::Gamification.status_for(user, :time_tracker_skills).score }.by(-1)
      end
    end
  end
end
