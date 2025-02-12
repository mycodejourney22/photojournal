# app/controllers/password_setups_controller.rb
class PasswordSetupsController < ApplicationController
  def edit
    @user = User.find_by(password_setup_token: params[:token])

    if @user.nil? || @user.password_setup_sent_at < 24.hours.ago
      redirect_to new_user_session_path, alert: 'This password setup link is invalid or has expired.'
    end
  end

  def update
    @user = User.find_by(password_setup_token: params[:token])

    if @user&.update(password_params)
      @user.update_columns(password_setup_token: nil, password_setup_sent_at: nil)
      redirect_to new_user_session_path, notice: 'Password has been set successfully. Please sign in.'
    else
      render :edit
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
