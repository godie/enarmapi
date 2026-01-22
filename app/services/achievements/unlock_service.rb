# frozen_string_literal: true

module Achievements
  class UnlockService
    def initialize(user)
      @user = user
    end

    def call
      unlocked_achievements = []
      Achievement.find_each do |achievement|
        next if @user.achievements.exists?(achievement.id)

        if criteria_met?(achievement)
          UserAchievement.create(user: @user, achievement: achievement)
          unlocked_achievements << achievement
        end
      end
      unlocked_achievements
    end

    private

    def criteria_met?(achievement)
      criteria = achievement.criteria.with_indifferent_access
      type = criteria[:type]

      case type
      when "exams_completed"
        check_exams_completed(criteria)
      when "category_accuracy"
        check_category_accuracy(criteria)
      when "correct_streak"
        false # Placeholder
      when "category_completion"
        false # Placeholder
      else
        Rails.logger.warn "Unknown achievement criteria type: #{type} for achievement #{achievement.id}"
        false
      end
    end

    def check_exams_completed(criteria)
      required_count = criteria[:count].to_i
      @user.taken_exams.count >= required_count
    end

    def check_category_accuracy(criteria)
      category_id = criteria[:category_id].to_i
      accuracy_threshold = criteria[:accuracy_threshold].to_f
      min_exams_in_category = (criteria[:min_exams_in_category] || 1).to_i

      user_exams_in_category = @user.user_exams.joins(:exam)
                                        .where(exams: { category_id: category_id })

      distinct_exams_taken_count = user_exams_in_category.select(:exam_id).distinct.count

      return false if distinct_exams_taken_count < min_exams_in_category

      correct_answers_in_category = @user.user_answers
                                           .joins(question: { clinical_case: :category })
                                           .where(categories: { id: category_id }, is_correct: true)
                                           .count

      total_answers_in_category = @user.user_answers
                                         .joins(question: { clinical_case: :category })
                                         .where(categories: { id: category_id })
                                         .count

      return false if total_answers_in_category.zero?

      accuracy = (correct_answers_in_category.to_f / total_answers_in_category) * 100
      accuracy >= accuracy_threshold
    end
  end
end
