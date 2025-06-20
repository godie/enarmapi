class Question < ApplicationRecord
  belongs_to :clinical_case
  has_one :category, through: :clinical_case
  has_many :answers, dependent: :destroy
  has_many :player_answers
  has_many :practicing_players, through: :player_answers, source: :player
  has_many :exam_questions
  has_many :exams, through: :exam_questions

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates :text, presence: true

  scope :with_clinical_case, -> { where.not(clinical_case_id: nil) }
  scope :standalone, -> { where(clinical_case_id: nil) }
  scope :by_category, ->(category_id) {
    joins(:clinical_case).where(clinical_cases: { category_id: category_id })
  }
  scope :by_clinical_case, ->(clinical_case_id) {
    where(clinical_case_id: clinical_case_id)
  }


  scope :not_practiced_by, ->(player) {
    where.not(id: player.practiced_questions.ids)
  }
end
