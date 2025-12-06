class ApplicationController < ActionController::API
  def current_user
    return @current_user if defined?(@current_user)

    header = request.headers["Authorization"]
    return nil unless header

    token = header.split(" ").last
    decoded = JwtService.decode(token)
    return nil unless decoded

    @current_user = User.find_by(id: decoded[:user_id])
  end

  def authenticate_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
  end
end
