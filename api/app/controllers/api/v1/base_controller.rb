require 'jwt'

class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_user

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    begin
      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
      @current_user_id = decoded_token[0]['user_id']
    rescue JWT::DecodeError
      render_unauthorized
    end
  end

  def set_current_user
    @current_user = User.find(@current_user_id) if @current_user_id
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_success(data = {}, message = 'Success')
    render json: { message: message, data: data }, status: :ok
  end
end
