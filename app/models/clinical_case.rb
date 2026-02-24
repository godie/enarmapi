class ClinicalCase < ApplicationRecord
  belongs_to :category
  has_one_attached :image
  has_many :questions, dependent: :destroy, inverse_of: :clinical_case
  accepts_nested_attributes_for :questions, allow_destroy: true
  self.per_page = 10

  enum :status, { pending: 0, published: 1, rejected: 2 }

  validates :name, presence: true
end
