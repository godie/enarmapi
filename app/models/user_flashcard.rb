class UserFlashcard < ApplicationRecord
  belongs_to :user
  belongs_to :flashcard

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :flashcard_id }

  scope :due, -> { where("next_review <= ?", Time.current) }

  # Simple SM-2 Algorithm adaptation
  def review(quality)
    # quality: 0-5
    # 0: total blackout, 1: incorrect, but remembered, 2: incorrect, but easy to recall
    # 3: correct, but difficult, 4: correct, after hesitation, 5: perfect response

    if quality >= 3
      if repetitions == 0
        self.interval = 1
      elsif repetitions == 1
        self.interval = 6
      else
        self.interval = (interval * ease_factor).round
      end
      self.repetitions += 1
      self.status = "reviewing"
    else
      self.repetitions = 0
      self.interval = 1
      self.status = "learning"
    end

    self.ease_factor = ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    self.ease_factor = 1.3 if ease_factor < 1.3
    self.next_review = Time.current + interval.days
    save!
  end
end
