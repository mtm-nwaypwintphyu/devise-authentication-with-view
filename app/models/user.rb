class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  has_many :posts, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]


  
  def self.from_omniauth(access_token)
    data = access_token.info
    credentials = access_token.credentials

    user = User.find_by(email: data['email'])

    if user
      user.provider ||= access_token.provider
      user.uid ||= access_token.uid
    else
      user = User.new(
        email: data['email'],
        password: Devise.friendly_token[0, 20],
        first_name: data['first_name'],
        last_name: data['last_name'],
        provider: access_token.provider,
        uid: access_token.uid
      )
    end

    user.google_oauth2_token = credentials.token
    user.google_oauth2_refresh_token = credentials.refresh_token if credentials.refresh_token.present?
    user.token_expires_at = Time.at(credentials.expires_at) if credentials.expires_at.present?

    user.save!
    user
  end

  validates :first_name, presence: { message: "First name cannot be blank" }
  validates :last_name, presence: { message: "Last name cannot be blank" }

end
