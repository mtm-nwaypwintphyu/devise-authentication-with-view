require "rails_helper"

RSpec.describe "Registration", type: :request do
  describe "POST /users" do
    context "when user param is valid" do
      before do
        Sidekiq::Worker.clear_all
      end
      let(:valid_params) do
          {
            user: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              email: Faker::Internet.unique.email,
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end
        it "return success" do
          post users_path, params: valid_params
          expect(response).to have_http_status(:see_other)
          follow_redirect!
          expect(response).to have_http_status(:ok)
        end

        it "enqueues analytics jobs" do
          expect {
            post users_path, params: valid_params
          }.to change(AnalyticsEventCreateJob.jobs, :size).by(1)
          .and change(GenerateExcelReportJob.jobs, :size).by(1)
          .and change(WelcomeEmailJob.jobs, :size).by(1)
        end
      end
    context "when user param is invalid" do
      let(:invalid_params) do
        {
          user: {
            first_name: "",
            last_name: "",
            email: Faker::Internet.unique.email,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
      it "return error" do
        post users_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
