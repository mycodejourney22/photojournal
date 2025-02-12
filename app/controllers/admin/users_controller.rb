# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  # before_action :require_super_admin
  before_action :set_user, only: [:edit, :update]

  def index
    @users = User.where.not(id: current_user.id)
  end

  def edit
  end

  def new
    @user = User.new
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: 'User role updated successfully.'
    else
      render :edit
    end
  end

  def create
    @user = User.new(user_params)
    @user.skip_password_validation = true

    if @user.save
      token = @user.generate_password_setup_token!
      UserMailer.password_setup_email(@user, token).deliver_later
      redirect_to admin_users_path, notice: 'User was successfully invited.'
    else
      render :new, status: :unprocessable_entity
    end
  end


  private

  def set_user
    @user = User.find(params[:id])
  end


  def user_params
    params.require(:user).permit(:email, :role)
  end

  def require_super_admin
    unless current_user.super_admin?
      redirect_to root_path, alert: 'Access denied.'
    end
  end
end
