module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: [ :me, :logout ]

      def signup
        user = User.new(signup_params)

        if user.save
          token = JwtService.encode(user_id: user.id)
          render json: {
            message: "Account created successfully",
            user: user_response(user),
            token: token
          }, status: :created
        else
          render json: {
            error: "Signup failed",
            errors: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: login_params[:email]&.downcase)

        if user&.authenticate(login_params[:password])
          if user.active?
            token = JwtService.encode(user_id: user.id)
            render json: {
              message: "Login successful",
              user: user_response(user),
              token: token
            }, status: :ok
          else
            render json: { error: "Account is deactivated" }, status: :forbidden
          end
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def logout
        render json: { message: "Logged out successfully" }, status: :ok
      end

      def me
        render json: {
          user: user_response(current_user)
        }, status: :ok
      end

      private

      def signup_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :role)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          role: user.role,
          created_at: user.created_at
        }
      end
    end
  end
end
