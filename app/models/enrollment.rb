class Enrollment < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :course

  validates :student, presence: true
  validates :course, presence: true
  validates :student_id, uniqueness: { scope: :course_id, message: "is already enrolled in this course" }
  validate :course_must_be_published, on: :create
  validate :student_must_be_student_role

  private

  def course_must_be_published
    errors.add(:course, "must be published to enroll") unless course&.published?
  end

  def student_must_be_student_role
    errors.add(:student, "must have student role") unless student&.student?
  end
end
