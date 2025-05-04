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
        format.html {redirect_to posts_path, notice: "Created"}
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
  end

  def edit
    @post = Post.find_by(id: params[:id])
  end

  def update
    @post = Post.find(params[:id])
    @post_usecase = Posts::PostUsecase.new(post_params.merge(user_id: current_user.id))
    response = @post_usecase.update(@post)

    respond_to do |format|
      if response[:status] == :updated
        format.html { redirect_to posts_path, notice: 'Post was successfully updated.' }
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
        format.html { redirect_to posts_url, notice:"Post deleted successfully" }
        format.json { head :no_content }
      end
    end
  end


  private
  
  def post_params
    params.require(:post).permit(:title, :content)
  end
  

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
