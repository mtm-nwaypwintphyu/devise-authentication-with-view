class WeeklyDigestJob 
  include Sidekiq::Job

  def perform(user_id)
    user = User.find(user_id)
    posts = user.posts.to_a 
    DigestMailer.weekly_digest(posts, user).deliver_later
  end
end
