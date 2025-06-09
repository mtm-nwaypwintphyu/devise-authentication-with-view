require "google/cloud/bigquery"

class GoogleCredentialsService
  def initialize(user)
    @user = user
  end

  def credentials
    creds = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: [
        "https://www.googleapis.com/auth/bigquery",
        "https://www.googleapis.com/auth/cloud-platform"
      ],
      access_token: @user.google_oauth2_token,
      refresh_token: @user.google_oauth2_refresh_token,
      expiration_time_millis: @user.token_expires_at.to_i * 1000
    )

    if creds.expired?
      creds.refresh!

      @user.update(
        google_oauth2_token: creds.access_token,
        token_expires_at: Time.at(creds.expires_at)
      )
    end

    creds
  end
end
