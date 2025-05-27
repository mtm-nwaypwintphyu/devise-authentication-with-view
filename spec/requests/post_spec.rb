require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let!(:posts) { FactoryBot.create_list(:post, 3, user: user) }

  describe "GET /posts" do
    context "when user is signed in" do
      before do
        sign_in user
        get posts_path
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "renders all posts" do
        posts.each do |post|
          expect(response.body).to include(post.title)
        end
      end
    end

    context "when user is not signed in" do
      before { get posts_path }

      it "redirects to sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /posts" do
    let(:user) { FactoryBot.create(:user) }

    context "when user is signed in" do
      before {
        sign_in user
        Sidekiq::Worker.clear_all
      }

      context "with valid parameters" do
        let(:valid_params) do
          {
            post: {
              title: "Test",
              content: "Content"
            }
          }
        end

        it "creates a new post" do
          expect {
            post posts_path, params: valid_params
          }.to change(Post, :count).by(1)

          expect(response).to redirect_to(posts_path)
          follow_redirect!
          expect(response.body).to include("Post created successfully")
        end

        it "enqueues the analytic job" do
          expect {
            post posts_path, params: valid_params
        }.to change(AnalyticsEventCreateJob.jobs, :size).by(1)
        end
      end
    end

    context "when user is not signed in" do
      let(:valid_params) do
        {
          post: {
            title: "Test",
            content: "Content"
          }
        }
      end

      it "redirects to sign in page" do
        post posts_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /posts.new" do
    context "when user is signed in" do
      before do
        sign_in user
        get new_post_path
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "renders the new post form" do
        expect(response.body).to include("Post Creation")
      end
    end

    context "when user is not signed in" do
      before { get new_post_path }

      it "redirect to sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /posts/:id/edit" do
    let(:user) { FactoryBot.create(:user) }
    let!(:post) { FactoryBot.create(:post, user: user) }

    context "when user is signed in" do
      before do
        sign_in user
        get edit_post_path(post)
      end
      it "returns http success" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include(post.title)
      end
    end
    context "when user is not sign in" do
      before do
        get edit_post_path(post)
      end
      it "redirect to sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /posts/:id" do
    let(:user) { FactoryBot.create(:user) }
    let(:post) { FactoryBot.create(:post, user: user) }
    context "when user is signed in" do
      before do
        sign_in user
        get post_path(post.id)
      end
      it "return http success" do
        expect(response).to have_http_status(:success)
      end
    end
    context "when user is not sign in" do
      before do
        get post_path(post.id)
      end

      it "redirect to sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # update post spec
  describe 'PATCH /posts/:id' do
    let(:user) { create(:user) }
    let!(:post) { create(:post, user: user) }
    let(:valid_params) { { post: { title: 'Update Title', content: 'Update content' } } }
    before {
            sign_in user
            Sidekiq::Worker.clear_all
          }

    it "update post and redirect " do
      patch post_path(post), params: valid_params
      expect(response).to redirect_to (posts_path)
      expect(flash.to_hash["notice"]).to eq('Post updated successfully.')
      expect(post.reload.title).to eq('Update Title')
    end
    it "enqueues the analytics job" do
     expect {
              patch post_path(post), params: valid_params
            }.to change(AnalyticsEventCreateJob.jobs, :size).by(1)
    end
  end

  # destroy post spec
  describe 'DELETE /posts/:id' do
    let(:user) { FactoryBot.create(:user) }
    let!(:post) { FactoryBot.create(:post, user: user) }

    context "when user is signed in" do
      before do
        sign_in user
      end

      it "returns deleted message" do
        delete post_path(post)
        expect(flash.to_hash["notice"]).to eq("Post deleted successfully")
      end
      it "enqueues the analytics job" do
        expect {
          delete post_path(post.id)
      }.to change(AnalyticsEventCreateJob.jobs, :size).by(1)
      end
    end
  end
end
