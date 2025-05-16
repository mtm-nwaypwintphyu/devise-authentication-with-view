class PostMailer < ApplicationMailer
  def create_email(user, title)
    @user = user
    @title = title
    mail(to: @user.email, subject: "New Post: #{@title} created alert.")
  end
end
