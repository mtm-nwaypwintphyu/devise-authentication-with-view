require 'google/apis/calendar_v3'
require 'googleauth'

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  has_many :posts, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  validates :first_name, presence: { message: "First name cannot be blank" }
  validates :last_name, presence: { message: "Last name cannot be blank" }


  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_initialize.tap do |user|
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.email = auth.info.email
      user.password ||= Devise.friendly_token[0, 20]

      user.google_oauth2_token = auth.credentials.token
      user.google_oauth2_refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token.present?
      user.token_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end

  def google_oauth_credentials
    Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: 'https://www.googleapis.com/auth/calendar.readonly',
      access_token: google_oauth2_token,
      refresh_token: google_oauth2_refresh_token,
      expires_at: token_expires_at.to_i
    )
  end  
end
