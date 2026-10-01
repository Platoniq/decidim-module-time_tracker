# frozen_string_literal: true

require "spec_helper"

module Decidim::TimeTracker
  shared_context "with an activity as the resource" do
    include_context "when a simple event"

    let(:time_tracker) { create(:time_tracker) }
    let(:task) { create(:task, time_tracker:) }
    let(:resource) { create(:activity, task:, description: { en: "Lay out the space (40%)" }) }
    let(:participatory_space) { time_tracker.component.participatory_space }
    let(:router) { Decidim::EngineRouter.main_proxy(time_tracker.component) }
  end

  shared_examples "an activity event" do
    it_behaves_like "a simple event"

    it "titles the notification with the activity, without its progress marker" do
      expect(subject.resource_title).to eq("Lay out the space")
    end

    it "names the space the activity belongs to" do
      expect(subject.email_intro).to include(decidim_sanitize_translated(participatory_space.title))
    end
  end

  describe AssignationAcceptedEvent do
    include_context "with an activity as the resource"

    let(:event_name) { "decidim.events.time_tracker.assignation_accepted_event" }

    it_behaves_like "an activity event"

    it "links the volunteer to the activity's public page" do
      expect(subject.resource_path).to eq(router.task_activity_path(task, resource))
    end
  end

  describe AssignationRejectedEvent do
    include_context "with an activity as the resource"

    let(:event_name) { "decidim.events.time_tracker.assignation_rejected_event" }

    it_behaves_like "an activity event"
  end

  describe AssignationRequestedEvent do
    include_context "with an activity as the resource"

    let(:event_name) { "decidim.events.time_tracker.assignation_requested_event" }

    it_behaves_like "an activity event"

    it "links the admin to the activity's assignations" do
      expect(subject.resource_path)
        .to eq(Decidim::EngineRouter.admin_proxy(time_tracker.component).task_activity_assignations_path(task, resource))
    end
  end

  describe SkillCertifiedEvent do
    include_context "when a simple event"

    let(:event_name) { "decidim.events.time_tracker.skill_certified_event" }
    let(:time_tracker) { create(:time_tracker) }
    let(:resource) { create(:task, time_tracker:, name: { en: "Trust-building workshops" }) }
    let(:participatory_space) { time_tracker.component.participatory_space }

    it_behaves_like "a simple event"

    context "when the task certifies an explicit skill" do
      let(:skill) { create(:skill, organization: participatory_space.organization, name: { en: "Group facilitation" }) }
      let(:extra) { { skill_id: skill.id } }

      it "names the skill, not the task" do
        expect(subject.resource_title).to eq("Group facilitation")
        expect(subject.email_intro).to include("Trust-building workshops")
      end
    end

    context "when the task certifies itself" do
      it "names the task" do
        expect(subject.resource_title).to eq("Trust-building workshops")
      end
    end
  end
end
