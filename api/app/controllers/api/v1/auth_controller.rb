require 'jwt'

class Api::V1::AuthController < ApplicationController
  def register
    user = User.new(user_params)
    
    if user.save
      token = generate_jwt_token(user.id)
      render json: {
        user: {
          id: user.id,
          email: user.email,
          created_at: user.created_at
        },
        token: token
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      token = generate_jwt_token(user.id)
      render json: {
        user: {
          id: user.id,
          email: user.email,
          created_at: user.created_at
        },
        token: token
      }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def me
    return render_unauthorized unless current_user

    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        created_at: current_user.created_at
      }
    }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def generate_jwt_token(user_id)
    JWT.encode({ user_id: user_id }, Rails.application.secret_key_base, 'HS256')
  end

  def current_user
    @current_user ||= begin
      token = request.headers['Authorization']&.split(' ')&.last
      return nil unless token

      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
      User.find(decoded_token[0]['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      nil
    end
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
