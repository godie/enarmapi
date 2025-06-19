# app/models/category.rb
class Category < ApplicationRecord
  # Asociaciones
  has_many :clinical_cases, dependent: :destroy
  has_many :questions, through: :clinical_cases

  # Validaciones
  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }

  # Callbacks
  before_save :normalize_name

  # Scopes
  scope :alphabetical, -> { order(:name) }
  scope :with_clinical_cases, -> { joins(:clinical_cases).distinct }
  scope :most_used, ->(limit) {
    left_joins(:clinical_cases)
      .group("categories.id")
      .order("COUNT(clinical_cases.id) DESC")
      .limit(limit)
  }

  def clinical_cases_count
    clinical_cases.count
  end

  def total_questions_count
    questions.count
  end

  def as_json(options = {})
    if options[:include_stats]
      super(options).merge(
        clinical_cases_count: clinical_cases_count,
        total_questions_count: total_questions_count
      )
    else
      super(options)
    end
  end

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end
end
