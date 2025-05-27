class Users::SessionsController < Devise::SessionsController
  after_action :send_weekly_digest, only: [ :create ]

  def create
    super do |resource|
      AnalyticsEventCreateJob.perform_async(
        resource.id,
        "user sign in",
        {
          "user_id" => resource.id,
          "first_name" => resource.first_name,
          "last_name" => resource.last_name,
          "email" => resource.email
        }
    )
    end
  end

  def destroy
     AnalyticsEventCreateJob.perform_async(
          current_user.id,
          "user sign out",
          {
            "user_id" => current_user.id,
            "first_name" => current_user.first_name,
            "last_name" => current_user.last_name,
            "email" => current_user.email
          }
        )
    super
  end

  private

  def send_weekly_digest
    WeeklyDigestJob.perform_async(current_user.id) if current_user
  end
end
