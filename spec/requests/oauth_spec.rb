require 'rails_helper'

RSpec.describe "Oauth", type: :request do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '12121212',
      info: {
        email: 'user@mail.com',
        name: 'Test User'
      }
    )
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  describe "GET /users/auth/google_oauth2/callback" do
    context 'when user is persisted' do
      let!(:user) { create(:user, email: Faker::Internet.unique.email) }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
      end

      it 'signin the user and redirects' do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(response.body).to include("Welcome to MyWebsite")
        expect(controller.current_user).to eq(user)
      end
    end

    context 'when user is not persisted' do
      let(:user) { instance_double(User, persisted?: false) }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
      end

      it 'redirect to registration page with alert' do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to redirect_to(new_user_registration_url)
        follow_redirect!

        expect(response.body).to include("Sign up")
      end
    end
  end
end
