module Posts
 class CsvDownloadUsecase
    def initialize(user)
      @user = user
    end

    def execute
      posts = Post.where(user_id: @user.id)
      Posts::CsvDownloadService.new(posts).process
    end
  end
end