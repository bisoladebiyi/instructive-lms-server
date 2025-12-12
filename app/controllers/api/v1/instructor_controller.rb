module Api
  module V1
    class InstructorController < ApplicationController
      before_action :authenticate_user!
      before_action :require_instructor

      # GET /api/v1/instructor/stats
      def stats
        courses = current_user.courses
        published_courses = courses.published
        total_students = Enrollment.where(course_id: courses.pluck(:id)).distinct.count(:student_id)

        render json: {
          courses: courses.count,
          published: published_courses.count,
          students: total_students,
          avg_rating: 0.0 # Placeholder - implement when ratings are added
        }, status: :ok
      end

      # GET /api/v1/instructor/students
      def students
        course_ids = current_user.courses.pluck(:id)
        enrollments = Enrollment.includes(:student, :course)
                                .where(course_id: course_ids)
                                .order(updated_at: :desc)

        # Apply filter
        if params[:filter].present? && params[:filter] != "all"
          case params[:filter]
          when "active"
            enrollments = enrollments.where("enrollments.updated_at > ?", 7.days.ago)
          when "inactive"
            enrollments = enrollments.where("enrollments.updated_at <= ?", 7.days.ago)
          end
        end

        # Apply search
        if params[:search].present?
          search_term = "%#{params[:search].downcase}%"
          enrollments = enrollments.joins(:student)
                                   .where("LOWER(users.first_name) LIKE :search OR LOWER(users.last_name) LIKE :search OR LOWER(users.email) LIKE :search",
                                          search: search_term)
        end

        # Apply limit
        enrollments = enrollments.limit(params[:limit].to_i) if params[:limit].present?

        render json: {
          students: enrollments.map { |enrollment| student_response(enrollment) }
        }, status: :ok
      end

      # GET /api/v1/instructor/courses/recent
      def recent_courses
        courses = current_user.courses
                              .order(created_at: :desc)
                              .limit(params[:limit] || 4)

        render json: {
          courses: courses.map { |course| course_summary_response(course) }
        }, status: :ok
      end

      private

      def require_instructor
        return if current_user.instructor?

        render json: { error: "Only instructors can access this resource" }, status: :forbidden
      end

      def student_response(enrollment)
        {
          id: enrollment.student.id,
          name: enrollment.student.full_name,
          email: enrollment.student.email,
          avatar: enrollment.student.avatar,
          course: enrollment.course.title,
          course_id: enrollment.course.id,
          progress: "#{enrollment.progress}%",
          enrolled_at: enrollment.enrolled_at,
          last_active: enrollment.updated_at.strftime("%b %d, %Y")
        }
      end

      def course_summary_response(course)
        {
          id: course.id,
          title: course.title,
          category: course.category,
          banner_image: course.banner_image,
          status: course.status,
          is_private: !course.published?,
          students_enrolled: course.enrollments.count,
          created_at: course.created_at
        }
      end
    end
  end
end
