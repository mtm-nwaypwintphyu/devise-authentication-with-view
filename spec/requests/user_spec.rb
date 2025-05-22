require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { FactoryBot.create(:user)}

  # index
  describe "GET /users" do
    context "when user is signed in" do
      before do
        sign_in user
        get users_path
      end

      it "return http success" do
        # check status
        expect(response).to have_http_status(:success)

        # check decorated or not
        expect(assigns(:users)).to be_a(Draper::CollectionDecorator)

        assigns(:users).each do |decorated_user|
          expect(decorated_user).to be_a(UserDecorator)
        end

      end
    end

    context "when user is not signed in" do
      it "redirect to sign in page" do
        get "/users"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # show
  describe "GET /users/:id" do
    
    context "when user is signed in" do

      before do
        sign_in user
        get "/users/#{user.id}"
      end

      it "return http success" do
        expect(response).to have_http_status(:success)

        expect(assigns(:user)).to eq(user)

        expect(response.body).to include(user.email)
        expect(response.body).to include(user.first_name)
        expect(response.body).to include(user.last_name)
      end
    end

    context "with incorrect user id" do
      before do
        sign_in user
        get '/users/22000'
      end
      it "redirect to users index with notice" do
        expect(response).to redirect_to(users_path)
        expect(flash[:notice]).to eq('User not found.')
      end
    end

    context "when user is not signed in" do
      it "redirect to sign in page" do
        get "/users/#{user.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # edit
  describe "GET /edit" do

    context "when user is signed in" do
      before do 
        sign_in user
        get "/users/#{user.id}/edit"
      end
      
      it "render the edit page successfully" do
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not signed in" do
      it "redirect to sign in page" do
        get edit_user_path(user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # update
  describe "PUT /update" do
    let(:valid_params) { { user: {first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.unique.email} } }
    let(:invalid_params) { { user: {first_name: "", last_name: "", email: Faker::Internet.unique.email} } }

    context "when user is signed in" do
      context "with valid params" do
        before do
          sign_in user  
          Sidekiq::Worker.clear_all 
          put user_path(user), params: valid_params
          
        end

        it "updates the user successfully" do
          user.reload
          expect(user.first_name).to eq(valid_params[:user][:first_name])
          expect(user.last_name).to eq(valid_params[:user][:last_name])
          expect(user.email).to eq(valid_params[:user][:email])
          expect(response).to redirect_to(users_path)
        end

        it "enqueues the analytics jobs" do
          expect{put user_path(user), params: valid_params}.to change(AnalyticsEventCreateJob.jobs, :size).by(1)
        end
      end

      context "with invalid params" do
        before do
          sign_in user
          put user_path(user), params: { user: invalid_params }
        end

        it "return unprocessible entity error" do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not signed in" do
      before do
        put "/users/#{user.id}", params: {
          user: {
            first_name: "Updated",
            last_name: "Name",
            email: "update@mail.com"
          }
        }
      end
      it "redirect to sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # destroy
  describe "DELETE /user" do
    context "when user is signed in" do
      before do
        sign_in user
        Sidekiq::Worker.clear_all 
      end
      it "redirect to users list" do
        delete user_path(user)
        expect(response).to redirect_to(users_path)
      end
      it "enqueue the analytics jobs" do
        expect{delete user_path(user)}.to change(AnalyticsEventCreateJob.jobs, :size).by(1)
      end
    end
    
    context "when user is not signed in" do
      it "redirect to user session path" do
        delete user_path(user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
