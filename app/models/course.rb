class Course < ApplicationRecord
  belongs_to :instructor, class_name: "User"
  has_many :sections, -> { order(position: :asc) }, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :student

  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :title, presence: true
  validates :instructor, presence: true

  scope :visible, -> { where(status: :published) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  accepts_nested_attributes_for :sections, allow_destroy: true

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def unpublish!
    update!(status: :draft, published_at: nil)
  end

  def enrolled_count
    enrollments.count
  end
end
