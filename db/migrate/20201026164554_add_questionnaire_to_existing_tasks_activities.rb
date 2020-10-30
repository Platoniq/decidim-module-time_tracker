# frozen_string_literal: true

class AddQuestionnaireToExistingTasksActivities < ActiveRecord::Migration[5.2]
  def change
    Decidim::TimeTracker::Task.transaction do
      Decidim::TimeTracker::Task.find_each do |task|
        if task.questionnaire.blank?
          task.update!(
            questionnaire: Decidim::Forms::Questionnaire.new
          )
        end
      end
    end
  end
end
