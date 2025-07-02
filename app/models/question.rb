class Question < ApplicationRecord
  belongs_to :clinical_case, optional: true, inverse_of: :questions
  # A question can also belong directly to a category if it's a standalone question
  belongs_to :category, optional: true

  has_many :answers, dependent: :destroy
  has_many :player_answers
  has_many :practicing_players, through: :player_answers, source: :player
  has_many :exam_questions, dependent: :destroy
  has_many :exams, through: :exam_questions

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates :text, presence: true
  validate :clinical_case_or_category_present

  scope :with_clinical_case, -> { where.not(clinical_case_id: nil) }
  scope :standalone, -> { where(clinical_case_id: nil) }

  # Updated scope to fetch questions by category, whether through a clinical case or directly.
  scope :by_category, ->(category_id) {
    left_joins(:clinical_case)
      .where(
        "(questions.category_id = :category_id) OR (clinical_cases.category_id = :category_id)",
        category_id: category_id
      )
  }

  scope :by_clinical_case, ->(clinical_case_id) {
    where(clinical_case_id: clinical_case_id)
  }

  scope :not_practiced_by, ->(player) {
    where.not(id: player.practiced_questions.ids)
  }

  # Method to get the category of the question, whether it's direct or via a clinical case.
  def effective_category
    category || clinical_case&.category
  end

  private

  # Validates that a question is associated with either a clinical case or a category directly.
  def clinical_case_or_category_present
    # Check presence of association object OR the foreign key.
    # The object (`clinical_case`) is present during nested build before save.
    # The ID (`clinical_case_id`) is present when loading from DB or if ID is set directly.
    is_associated_with_clinical_case = clinical_case.present? || clinical_case_id.present?
    is_associated_with_category = category.present? || category_id.present?

    if !is_associated_with_clinical_case && !is_associated_with_category
      errors.add(:base, "Question must be associated with a clinical case or a category")
    end

    # This condition remains the same: a question cannot be linked to a standalone category
    # if it's already linked to a clinical case (which itself has a category).
    # clinical_case_id.present? implies it's not a new record being built by parent where ID is not yet set.
    if is_associated_with_clinical_case && category_id.present?
      errors.add(:base, "Question cannot be associated with both a clinical case and a category directly")
    end
  end
end
