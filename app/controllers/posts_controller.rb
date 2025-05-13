class PostsController < ApplicationController
  before_action :authenticate_user!
  require 'csv'
  
  # get all posts
  def index
    @posts = Post.all
  end

  # to new post form
  def new
    @post = Posts::PostForm.new
  end
  
  # create post 
  def create
    respond_to do |format|
      @post = Posts:: PostUsecase.new(post_params.merge(user_id: current_user.id))
      response = @post.create
      if response[:status] == :created
        format.html {redirect_to posts_path, notice: "Post created successfully."}
      else
        @post = Posts::PostForm.new(post_params.merge(user_id: current_user.id))
        @post.errors.add(:title, response[:errors][:title]) if response[:errors][:title]
        @post.errors.add(:content, response[:errors][:content]) if response[:errors][:content]
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # to post csv upload form
  def upload_csv_form
    @post = Posts::PostForm.new
  end

  # to download sample csv
  def download_sample_csv
    csv_content = CSV.generate(headers: true) do |csv|
      csv << ["Title","Content"]
      csv << ["Sample post", "This is sample content."]
    end
    # Send the CSV data as a file download
    send_data  csv_content, filename: "sample_posts.csv",type: "text/csv"
  end

  # to create posts from csv
  def upload_csv
   if params[:csv_file].present?

      result = Posts::CsvUploadUsecase.new(params[:csv_file],current_user).execute
      if result.success?
        redirect_to posts_path, notice: 'CSV file uploaded and posts created successfully.'
      else
        redirect_to upload_csv_form_posts_path, notice: result.error
      end
   else
     redirect_to upload_csv_form_posts_path , notice: 'Please select a CSV file to upload.'
   end
  end

  # to download all posts
  def download
    posts = Post.all 

    begin
      csv_content = Posts::CsvDownloadService.new(posts).process
      send_data csv_content,filename: "posts_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv",type: "text/csv"
    rescue => e
      flash[:notice] = e.message 
      redirect_to posts_path 
    end
  end

  # to show post
  def show
    @post = Post.find_by(id: params[:id])

    if @post
      @post.user = @post.user.decorate
    else
      flash[:alert] = "Post not found"
      redirect_to posts_path
    end
  end

  # to edit post
  def edit
    @post = Post.find_by(id: params[:id])
    @post.user = @post.user.decorate
  end

  # to update post
  def update
    @post = Post.find(params[:id])
    @post_usecase = Posts::PostUsecase.new(post_params.merge(user_id: current_user.id))
    response = @post_usecase.update(@post)

    respond_to do |format|
      if response[:status] == :updated
        format.html { redirect_to posts_path, notice: 'Post updated successfully.' }
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

  # to delete post
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
  
  # Strong parameters for post creation and update
  def post_params
    params.require(:post).permit(:title, :content)
  end
end
