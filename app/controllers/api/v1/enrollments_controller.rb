module Api
  module V1
    class EnrollmentsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_student
      before_action :set_course, only: [ :enroll, :unenroll, :progress ]

      # GET /api/v1/enrollments
      def index
        @enrollments = current_user.enrollments.includes(course: :instructor)

        render json: {
          enrollments: @enrollments.map { |enrollment| enrollment_response(enrollment) }
        }, status: :ok
      end

      # POST /api/v1/courses/:course_id/enroll
      def enroll
        @enrollment = current_user.enrollments.build(course: @course)

        if @enrollment.save
          render json: {
            message: "Successfully enrolled in course",
            enrollment: enrollment_response(@enrollment)
          }, status: :created
        else
          render json: {
            error: "Failed to enroll",
            errors: @enrollment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/courses/:course_id/unenroll
      def unenroll
        @enrollment = current_user.enrollments.find_by(course: @course)

        if @enrollment
          @enrollment.destroy
          render json: { message: "Successfully unenrolled from course" }, status: :ok
        else
          render json: { error: "You are not enrolled in this course" }, status: :not_found
        end
      end

      # GET /api/v1/courses/:course_id/progress
      def progress
        @enrollment = current_user.enrollments.find_by(course: @course)

        if @enrollment
          # TODO: Calculate actual progress from completed lessons when lessons are implemented
          total_lessons = @course.sections.count # Placeholder until lessons exist
          completed_lessons = 0

          render json: {
            course_id: @course.id,
            course_title: @course.title,
            is_enrolled: true,
            progress: @enrollment.progress,
            total_lessons: total_lessons,
            completed_lessons: completed_lessons,
            enrolled_at: @enrollment.enrolled_at,
            completed_at: @enrollment.completed_at
          }, status: :ok
        else
          render json: {
            course_id: @course.id,
            is_enrolled: false,
            progress: 0
          }, status: :ok
        end
      end

      private

      def require_student
        return if current_user.student?

        render json: { error: "Only students can perform this action" }, status: :forbidden
      end

      def set_course
        @course = Course.find(params[:course_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Course not found" }, status: :not_found
      end

      def enrollment_response(enrollment)
        {
          id: enrollment.id,
          progress: enrollment.progress,
          enrolled_at: enrollment.enrolled_at,
          completed_at: enrollment.completed_at,
          course: {
            id: enrollment.course.id,
            title: enrollment.course.title,
            description: enrollment.course.description,
            category: enrollment.course.category,
            duration: enrollment.course.duration,
            banner_image: enrollment.course.banner_image,
            instructor: {
              id: enrollment.course.instructor.id,
              name: enrollment.course.instructor.full_name
            }
          }
        }
      end
    end
  end
end
