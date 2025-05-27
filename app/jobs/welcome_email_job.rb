class WelcomeEmailJob
 include Sidekiq::Worker

  def perform(user_id)
      user = User.find(user_id)
      UserMailer.welcome_email(user).deliver_later
  end
end
