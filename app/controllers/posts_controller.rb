class PostsController < ApplicationController
  before_action :authenticate_user!

  def index
    @posts = Post.all
  end

  def new
    @post = Posts::PostForm.new
  end

  def create
    respond_to do |format|
      @post = Posts:: PostUsecase.new(post_params.merge(user_id: current_user.id))
      response = @post.create
      if response[:status] == :created
        AnalyticsEventCreateJob.perform_async(
          current_user.id,
          "post create",
          {
            "create_user" => current_user.first_name + " "+ current_user.last_name,
            "post_title" => post_params[:title],
            "post_content" => post_params[:content]
          }
        )
        PostCreatedMailJob.perform_later(post_params.merge(user: current_user))
        format.html { redirect_to posts_path, notice: "Post created successfully." }
      else
        @post = Posts::PostForm.new(post_params.merge(user_id: current_user.id))
        @post.errors.add(:title, response[:errors][:title]) if response[:errors][:title]
        @post.errors.add(:content, response[:errors][:content]) if response[:errors][:content]
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def show
    @post = Post.find_by(id: params[:id])
    @post.user = @post.user.decorate
  end

  def edit
    @post = Post.find_by(id: params[:id])
    @post.user = @post.user.decorate
  end

  def update
    @post = Post.find(params[:id])
    @post_usecase = Posts::PostUsecase.new(post_params.merge(user_id: current_user.id))
    response = @post_usecase.update(@post)

    respond_to do |format|
      if response[:status] == :updated
         AnalyticsEventCreateJob.perform_async(
          current_user.id,
          "post update",
          {
            "update_user" => current_user.first_name + " "+ current_user.last_name,
            "post_title" => post_params[:title],
            "post_content" => post_params[:content]
          }
        )
        format.html { redirect_to posts_path, notice: "Post updated successfully." }
        format.json { render :show, status: :ok, location: @post }
      else
        @post = Posts::PostForm.new(post_params.merge(user_id: current_user.id))
        @post.errors.add(:title, response[:errors][:title]) if response[:errors][:title]
        @post.errors.add(:content, response[:errors][:content]) if response[:errors][:content]
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post_usecase = Posts::PostUsecase.new(nil)
    response = @post_usecase.destroy(@post)

    respond_to do |format|
      if response
         AnalyticsEventCreateJob.perform_async(
          current_user.id,
          "post delete",
          {
            "delete_user" => current_user.first_name + " "+ current_user.last_name,
            "post_title" => @post.title,
            "post_content" => @post.content
          }
        )
        format.html { redirect_to posts_url, notice: "Post deleted successfully" }
        format.json { head :no_content }
      end
    end
  end


  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
