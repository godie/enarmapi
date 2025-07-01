class ClinicalCase < ApplicationRecord
  belongs_to :category
  has_many :questions, dependent: :destroy, inverse_of: :clinical_case
  accepts_nested_attributes_for :questions, allow_destroy: true
  self.per_page = 10

  validates :name, presence: true
end
