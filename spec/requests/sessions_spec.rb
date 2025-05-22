require 'rails_helper'

RSpec.describe "Session", type: :request do
  let(:user) { create(:user, password: "password") }
  before do
    Sidekiq::Worker.clear_all
  end

  describe "POST /users/sign_in" do
    context "with valid credentials" do
      it "signs in the user and enqueues jobs" do
        expect {
          post user_session_path, params: { user: { email: user.email, password: "password" } }
        }.to change { AnalyticsEventCreateJob.jobs.size }.by(1)
         .and change { WeeklyDigestJob.jobs.size }.by(1)

        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "does not sign in the user or enqueue jobs" do
        expect {
          post user_session_path, params: { user: { email: user.email, password: "wrong" } }
        }.not_to change { AnalyticsEventCreateJob.jobs.size }

        expect(response.body).to include("Invalid Email or password")
      end
    end
  end

  describe "DELETE /users/sign_out" do
    before do
      sign_in user
    end

    it "signs out the user and enqueues sign-out analytics job" do
      expect {
        delete destroy_user_session_path
      }.to change { AnalyticsEventCreateJob.jobs.size }.by(1)

      expect(response).to redirect_to(root_path)
    end
  end
end
