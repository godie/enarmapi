class ClinicalCase < ApplicationRecord
  MAX_IMAGE_SIZE = 5.megabytes
  ALLOWED_IMAGE_TYPES = [ "image/png", "image/jpeg" ].freeze

  belongs_to :category
  has_one_attached :image
  has_many :questions, dependent: :destroy, inverse_of: :clinical_case
  accepts_nested_attributes_for :questions, allow_destroy: true
  self.per_page = 10

  enum :status, { pending: 0, published: 1, rejected: 2 }

  validates :name, presence: true
  validate :image_must_be_valid

  def tag_list
    tags&.split(",")&.map(&:strip) || []
  end

  private

  def image_must_be_valid
    return unless image.attached?

    unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
      errors.add(:image, "debe ser PNG o JPG")
    end

    if image.blob.byte_size > MAX_IMAGE_SIZE
      errors.add(:image, "no debe superar 5 MB")
    end
  end
end
