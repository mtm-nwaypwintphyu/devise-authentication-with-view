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
      user
    end
  end 

   def refresh_access_token
    return false unless google_oauth2_refresh_token.present?

    client_id = ENV['GOOGLE_CLIENT_ID']
    client_secret = ENV['GOOGLE_CLIENT_SECRET']

    response = Faraday.post('https://oauth2.googleapis.com/token', {
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: google_oauth2_refresh_token,
      grant_type: 'refresh_token'
    })

    if response.status == 200
      body = JSON.parse(response.body)
      update(
        google_oauth2_token: body['access_token'],
        token_expires_at: Time.now + body['expires_in'].to_i.seconds
      )
      true
    else
      false
    end
  end
end
  