module Posts
  class PostService

    def initialize(params)
      @params = params
    end

    def create
      post = Post.new(@params)
      if post.save
        return {post: post, status: :created}
      else
        return {post: post, status: :unprocessable_entity}
      end
    end

    def update(updated_post)
      if updated_post.update(@params)
        return { post: updated_post, status: :updated }
      else
        return { post: updated_post, status: :unprocessable_entity }
      end
    end

    def destroy(deleted_post)
      post = Post.find(deleted_post[:id])
      if post.destroy
        return true
      else
        return false
      end
    end

    
  end
end