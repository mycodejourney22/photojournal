# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def password_setup_email(user, token)
    @user = user
    @setup_url = password_setup_url(token)
    mail(to: @user.email, subject: 'Set up your account')
  end
end
