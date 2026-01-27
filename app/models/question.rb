class Question < ApplicationRecord
  belongs_to :clinical_case, optional: true, inverse_of: :questions
  belongs_to :category, optional: true

  has_many :answers, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :practicing_users, through: :user_answers, source: :user
  has_many :exam_questions, dependent: :destroy
  has_many :exams, through: :exam_questions

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates :text, presence: true
  validate :clinical_case_or_category_present

  scope :with_clinical_case, -> { where.not(clinical_case_id: nil) }
  scope :standalone, -> { where(clinical_case_id: nil) }

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

  scope :not_practiced_by, ->(user) {
    where.not(id: user.practiced_questions.ids)
  }

  def effective_category
    category || clinical_case&.category
  end

  private

  def clinical_case_or_category_present
    is_associated_with_clinical_case = clinical_case.present? || clinical_case_id.present?
    is_associated_with_category = category.present? || category_id.present?

    if !is_associated_with_clinical_case && !is_associated_with_category
      errors.add(:base, "La pregunta debe estar asociada a un caso clínico o a una categoría")
    end

    if is_associated_with_clinical_case && category_id.present?
      errors.add(:base, "La pregunta no puede estar asociada a un caso clínico y a una categoría directamente")
    end
  end
end
