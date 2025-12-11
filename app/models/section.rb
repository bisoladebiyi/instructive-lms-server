class Section < ApplicationRecord
  belongs_to :course

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_position, on: :create

  private

  def set_position
    self.position ||= (course&.sections&.maximum(:position) || -1) + 1
  end
end
