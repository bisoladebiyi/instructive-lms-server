module Api
  module V1
    class CoursesController < ApplicationController
      before_action :authenticate_user!
      before_action :require_instructor, except: [ :index, :show ]
      before_action :set_course, only: [ :show, :update, :destroy, :publish, :unpublish ]
      before_action :authorize_course, only: [ :update, :destroy, :publish, :unpublish ]

      # GET /api/v1/courses
      def index
        if current_user.instructor?
          @courses = current_user.courses.includes(:sections)
        else
          @courses = Course.visible.includes(:instructor, :sections)
        end

        @courses = @courses.by_category(params[:category]) if params[:category].present?

        render json: {
          courses: @courses.map { |course| course_response(course) }
        }, status: :ok
      end

      # GET /api/v1/courses/:id
      def show
        # Students can only view published courses
        if current_user.student? && !@course.published?
          render json: { error: "Course not found" }, status: :not_found
          return
        end

        render json: {
          course: course_response(@course, include_sections: true)
        }, status: :ok
      end

      # POST /api/v1/courses
      def create
        @course = current_user.courses.build(course_params)

        if @course.save
          create_sections if params[:course][:sections].present?

          render json: {
            message: "Course created successfully",
            course: course_response(@course.reload, include_sections: true)
          }, status: :created
        else
          render json: {
            error: "Failed to create course",
            errors: @course.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/courses/:id
      def update
        if @course.update(course_params)
          update_sections if params[:course][:sections].present?

          render json: {
            message: "Course updated successfully",
            course: course_response(@course.reload, include_sections: true)
          }, status: :ok
        else
          render json: {
            error: "Failed to update course",
            errors: @course.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/courses/:id
      def destroy
        @course.destroy
        render json: { message: "Course deleted successfully" }, status: :ok
      end

      # POST /api/v1/courses/:id/publish
      def publish
        @course.publish!
        render json: {
          message: "Course published successfully",
          course: course_response(@course)
        }, status: :ok
      end

      # POST /api/v1/courses/:id/unpublish
      def unpublish
        @course.unpublish!
        render json: {
          message: "Course unpublished successfully",
          course: course_response(@course)
        }, status: :ok
      end

      private

      def set_course
        @course = Course.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Course not found" }, status: :not_found
      end

      def authorize_course
        return if @course.instructor_id == current_user.id

        render json: { error: "You are not authorized to perform this action" }, status: :forbidden
      end

      def require_instructor
        return if current_user.instructor?

        render json: { error: "Only instructors can perform this action" }, status: :forbidden
      end

      def course_params
        params.require(:course).permit(
          :title,
          :description,
          :category,
          :duration,
          :banner_image,
          learning_points: []
        )
      end

      def create_sections
        sections_data = params[:course][:sections]
        sections_data.each_with_index do |section_title, index|
          @course.sections.create!(title: section_title, position: index) if section_title.present?
        end
      end

      def update_sections
        # Remove existing sections and recreate
        @course.sections.destroy_all
        create_sections
      end

      def course_response(course, include_sections: false)
        response = {
          id: course.id,
          title: course.title,
          description: course.description,
          category: course.category,
          duration: course.duration,
          banner_image: course.banner_image,
          learning_points: course.learning_points || [],
          status: course.status,
          is_private: !course.published?,
          published_at: course.published_at,
          students_enrolled: course.enrolled_count,
          instructor: {
            id: course.instructor.id,
            name: course.instructor.full_name,
            email: course.instructor.email
          },
          created_at: course.created_at,
          updated_at: course.updated_at
        }

        if include_sections
          response[:sections] = course.sections.map do |section|
            {
              id: section.id,
              title: section.title,
              position: section.position
            }
          end
        end

        response
      end
    end
  end
end
