class LessonCompletion < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :lesson

  validates :student, presence: true
  validates :lesson, presence: true
  validates :student_id, uniqueness: { scope: :lesson_id, message: "has already completed this lesson" }
  validate :student_must_be_enrolled

  private

  def student_must_be_enrolled
    return unless student && lesson

    course = lesson.section.course
    unless student.enrollments.exists?(course: course)
      errors.add(:student, "must be enrolled in the course")
    end
  end
end
