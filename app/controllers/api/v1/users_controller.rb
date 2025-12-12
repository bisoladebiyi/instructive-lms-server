module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/users/profile
      def profile
        render json: {
          user: user_profile_response(current_user)
        }, status: :ok
      end

      # PUT /api/v1/users/profile
      def update_profile
        if current_user.update(profile_params)
          render json: {
            message: "Profile updated successfully",
            user: user_profile_response(current_user)
          }, status: :ok
        else
          render json: {
            error: "Failed to update profile",
            errors: current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/users/change-password
      def change_password
        unless current_user.authenticate(password_params[:current_password])
          render json: { error: "Current password is incorrect" }, status: :unprocessable_entity
          return
        end

        if password_params[:new_password] != password_params[:confirm_password]
          render json: { error: "New password and confirmation do not match" }, status: :unprocessable_entity
          return
        end

        if current_user.update(password: password_params[:new_password])
          render json: { message: "Password changed successfully" }, status: :ok
        else
          render json: {
            error: "Failed to change password",
            errors: current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:user).permit(:first_name, :last_name, :email, :phone, :bio, :avatar)
      end

      def password_params
        params.require(:user).permit(:current_password, :new_password, :confirm_password)
      end

      def user_profile_response(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          phone: user.phone,
          bio: user.bio,
          avatar: user.avatar,
          role: user.role,
          created_at: user.created_at
        }
      end
    end
  end
end
