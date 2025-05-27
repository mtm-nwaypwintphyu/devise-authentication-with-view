require 'rails_helper'
require 'googleauth'

RSpec.describe User, type: :model do
  # test factory
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  # test validation
  describe "validations" do
    # without first name
    it "is invalid without a first_name" do
      user = build(:user, first_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("First name cannot be blank")
    end

    # without last name
    it "is invalid without a last_name" do
      user = build(:user, last_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("Last name cannot be blank")
    end
  end

  # test validation
  describe "associations" do
    it { should have_many(:posts).dependent(:destroy) }
  end

  # tesh google user creation
  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        info: {
          email: "test3@gmail.com",
          first_name: "test",
          last_name: "user"
        },
        credentials: {
          token: "access-token",
          refresh_token: "refresh-token",
          expires_at: Time.now.to_i + 1.hour.to_i
        }
      )
    end

    # destroy previous user
    before do
      User.where(email: auth.info.email).destroy_all
    end

    it "creates a new user if one does not exist" do
      expect {
        User.from_omniauth(auth)
    }.to change(User, :count).by(1)
    end
  end

  # test background job
  describe "send weekly digest" do
    before do
      Sidekiq::Worker.clear_all
    end
    let(:user) { create(:user) }

    it 'enques the weekly digest job with the user id' do
      expect {
        user.send_weekly_digest
    }.to change { WeeklyDigestJob.jobs.size }.by(1)
    end
  end
end
