class UserMailer < ApplicationMailer
  default from: "crud.npp@mail.com"

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Welcome to My Awesome Site")
  end
end
