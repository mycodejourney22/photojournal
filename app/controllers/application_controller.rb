class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Use a single line for both :verify_authorized and :verify_policy_scoped


  private

  def skip_pundit?
    result = devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
    Rails.logger.debug "skip_pundit? result: #{result} for #{params[:controller]}##{params[:action]}"
    result
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end



end
