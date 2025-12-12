module Api
  module V1
    class StudentController < ApplicationController
      before_action :authenticate_user!
      before_action :require_student

      # GET /api/v1/student/stats
      def stats
        enrollments = current_user.enrollments
        completed_courses = enrollments.where.not(completed_at: nil).count

        # Total hrs
        completed_lesson_ids = current_user.lesson_completions.pluck(:lesson_id)
        total_minutes = Lesson.where(id: completed_lesson_ids)
                              .pluck(:duration)
                              .sum { |d| parse_duration_to_minutes(d) }
        hours_learned = (total_minutes / 60.0).round(1)

        render json: {
          enrolled_courses: enrollments.count,
          completed_courses: completed_courses,
          hours_learned: hours_learned,
          certificates: completed_courses # Certificates equal completed courses for now
        }, status: :ok
      end

      # GET /api/v1/student/courses/recent
      def recent_courses
        enrollments = current_user.enrollments
                                  .includes(course: :instructor)
                                  .order(updated_at: :desc)
                                  .limit(params[:limit] || 4)

        render json: {
          courses: enrollments.map { |enrollment| enrolled_course_response(enrollment) }
        }, status: :ok
      end

      private

      def require_student
        return if current_user.student?

        render json: { error: "Only students can access this resource" }, status: :forbidden
      end

      def parse_duration_to_minutes(duration_string)
        return 0 if duration_string.blank?

        minutes = 0
        if duration_string =~ /(\d+)h/
          minutes += ::Regexp.last_match(1).to_i * 60
        end
        if duration_string =~ /(\d+)m/
          minutes += ::Regexp.last_match(1).to_i
        end
        minutes
      end

      def enrolled_course_response(enrollment)
        {
          id: enrollment.course.id,
          title: enrollment.course.title,
          category: enrollment.course.category,
          banner_image: enrollment.course.banner_image,
          duration: enrollment.course.duration,
          progress: enrollment.progress,
          enrolled_at: enrollment.enrolled_at,
          completed_at: enrollment.completed_at,
          instructor: {
            id: enrollment.course.instructor.id,
            name: enrollment.course.instructor.full_name,
            avatar: enrollment.course.instructor.avatar
          }
        }
      end
    end
  end
end
