class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :content, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :between, ->(user1_id, user2_id) {
    where("(sender_id = :u1 AND receiver_id = :u2) OR (sender_id = :u2 AND receiver_id = :u1)",
          u1: user1_id, u2: user2_id)
  }
end
