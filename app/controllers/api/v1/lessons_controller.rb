module Api
  module V1
    class LessonsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_course
      before_action :set_lesson, only: [ :show, :update, :destroy, :complete ]
      before_action :require_instructor, only: [ :create, :update, :destroy ]
      before_action :authorize_course, only: [ :create, :update, :destroy ]
      before_action :require_student, only: [ :complete ]
      before_action :require_enrollment, only: [ :complete ]

      # GET /api/v1/courses/:course_id/lessons
      def index
        @lessons = @course.sections.includes(:lessons).flat_map(&:lessons)

        render json: {
          course_id: @course.id,
          sections: sections_with_lessons
        }, status: :ok
      end

      # GET /api/v1/courses/:course_id/lessons/:id
      def show
        render json: {
          lesson: lesson_response(@lesson)
        }, status: :ok
      end

      # POST /api/v1/courses/:course_id/lessons
      def create
        @section = @course.sections.find_by(id: lesson_params[:section_id])

        unless @section
          render json: { error: "Section not found" }, status: :not_found
          return
        end

        @lesson = @section.lessons.build(lesson_params.except(:section_id))

        if @lesson.save
          render json: {
            message: "Lesson created successfully",
            lesson: lesson_response(@lesson)
          }, status: :created
        else
          render json: {
            error: "Failed to create lesson",
            errors: @lesson.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/courses/:course_id/lessons/:id
      def update
        # Handle section change if provided
        if lesson_params[:section_id].present? && lesson_params[:section_id] != @lesson.section_id
          new_section = @course.sections.find_by(id: lesson_params[:section_id])
          unless new_section
            render json: { error: "Section not found" }, status: :not_found
            return
          end
        end

        if @lesson.update(lesson_params.except(:section_id).merge(
          lesson_params[:section_id].present? ? { section_id: lesson_params[:section_id] } : {}
        ))
          render json: {
            message: "Lesson updated successfully",
            lesson: lesson_response(@lesson)
          }, status: :ok
        else
          render json: {
            error: "Failed to update lesson",
            errors: @lesson.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/courses/:course_id/lessons/:id
      def destroy
        @lesson.destroy
        render json: { message: "Lesson deleted successfully" }, status: :ok
      end

      # POST /api/v1/courses/:course_id/lessons/:id/complete
      def complete
        completion = current_user.lesson_completions.find_or_initialize_by(lesson: @lesson)

        if completion.persisted?
          render json: {
            message: "Lesson already completed",
            lesson: lesson_response(@lesson)
          }, status: :ok
        elsif completion.save
          update_enrollment_progress
          render json: {
            message: "Lesson marked as complete",
            lesson: lesson_response(@lesson)
          }, status: :ok
        else
          render json: {
            error: "Failed to mark lesson as complete",
            errors: completion.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_course
        @course = Course.find(params[:course_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Course not found" }, status: :not_found
      end

      def set_lesson
        @lesson = Lesson.joins(:section).where(sections: { course_id: @course.id }).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Lesson not found" }, status: :not_found
      end

      def require_instructor
        return if current_user.instructor?

        render json: { error: "Only instructors can perform this action" }, status: :forbidden
      end

      def require_student
        return if current_user.student?

        render json: { error: "Only students can perform this action" }, status: :forbidden
      end

      def authorize_course
        return if @course.instructor_id == current_user.id

        render json: { error: "You are not authorized to perform this action" }, status: :forbidden
      end

      def require_enrollment
        return if current_user.enrollments.exists?(course: @course)

        render json: { error: "You must be enrolled in this course" }, status: :forbidden
      end

      def lesson_params
        params.require(:lesson).permit(
          :title,
          :duration,
          :lesson_type,
          :video_url,
          :text_content,
          :pdf_url,
          :position,
          :section_id
        )
      end

      def lesson_response(lesson)
        response = {
          id: lesson.id,
          title: lesson.title,
          duration: lesson.duration,
          type: lesson.lesson_type,
          video_url: lesson.video_url,
          text_content: lesson.text_content,
          pdf_url: lesson.pdf_url,
          position: lesson.position,
          section_id: lesson.section_id,
          section_title: lesson.section.title,
          created_at: lesson.created_at,
          updated_at: lesson.updated_at
        }

        if current_user.student?
          response[:is_completed] = lesson.completed_by?(current_user)
        end

        response
      end

      def sections_with_lessons
        @course.sections.includes(:lessons).map do |section|
          {
            id: section.id,
            title: section.title,
            position: section.position,
            lessons: section.lessons.map do |lesson|
              {
                id: lesson.id,
                title: lesson.title,
                duration: lesson.duration,
                type: lesson.lesson_type,
                position: lesson.position,
                is_completed: current_user.student? ? lesson.completed_by?(current_user) : nil
              }
            end
          }
        end
      end

      def update_enrollment_progress
        enrollment = current_user.enrollments.find_by(course: @course)
        return unless enrollment

        total_lessons = Lesson.joins(:section).where(sections: { course_id: @course.id }).count
        completed_lessons = current_user.lesson_completions
                                        .joins(lesson: :section)
                                        .where(sections: { course_id: @course.id })
                                        .count

        progress = total_lessons > 0 ? (completed_lessons.to_f / total_lessons * 100).round : 0
        enrollment.update(
          progress: progress,
          completed_at: progress == 100 ? Time.current : nil
        )
      end
    end
  end
end
