class Lesson < ApplicationRecord
  belongs_to :section
  has_one :course, through: :section
  has_many :lesson_completions, dependent: :destroy

  enum :lesson_type, { video: 0, text: 1, pdf: 2 }

  validates :title, presence: true
  validates :lesson_type, presence: true
  validates :video_url, presence: true, if: :video?
  validates :text_content, presence: true, if: :text?
  validates :pdf_url, presence: true, if: :pdf?

  before_validation :set_position, on: :create

  def completed_by?(user)
    lesson_completions.exists?(student: user)
  end

  private

  def set_position
    self.position ||= (section&.lessons&.maximum(:position) || -1) + 1
  end
end
