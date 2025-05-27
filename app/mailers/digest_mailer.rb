class DigestMailer < ApplicationMailer
  default from: "crud.npp@mail.com"

   def weekly_digest(posts, user)
    @posts = posts
    @user = user
    mail(to: @user.email, subject: "Your posts in a week.")
  end
end
