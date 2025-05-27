module Posts
  class PostService
    def initialize(params)
      @params = params
    end

    def create
      post = Post.new(@params)
      if post.save
        { post: post, status: :created }
      else
        { post: post, status: :unprocessable_entity }
      end
    end

    def update(updated_post)
      if updated_post.update(@params)
        { post: updated_post, status: :updated }
      else
        { post: updated_post, status: :unprocessable_entity }
      end
    end

    def destroy(deleted_post)
      post = Post.find(deleted_post[:id])
      if post.destroy
        true
      else
        false
      end
    end
  end
end
