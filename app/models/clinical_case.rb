class ClinicalCase < ApplicationRecord
  belongs_to :category
  has_many :questions
  accepts_nested_attributes_for :questions
  self.per_page = 10
end
