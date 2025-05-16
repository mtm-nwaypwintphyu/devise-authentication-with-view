class AnalyticsEventCreateJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(user_id, action, details = {})
    user = User.find(user_id)
    return unless user
    AnalyticsEvent.create!(
      user_id: user.id,
      action: action,
      details: details
    )
  end
end
