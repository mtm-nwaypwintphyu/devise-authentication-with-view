require_relative '../../forms/posts/post_form.rb'
module Posts
  class PostUsecase < BaseUsecase
    def initialize(params)
      @params = params      
      @form = Posts::PostForm.new(params)
    end
    def create
      begin
        post_create_service = Posts::PostService.new(@form.attributes)
        if @form.valid?
          response = post_create_service.create
        else
          post = Post.new(@form.attributes)
          post.errors.add(:title, @form.errors[:title]) if @form.errors[:title].any?
          post.errors.add(:content, @form.errors[:content]) if @form.errors[:content].any?
    
          return { post: @form, errors: post.errors, status: :unprocessable_entity }
        end
      rescue StandardError => errors
        return {post: post, errors: errors.message, status: :unprocessable_entity}
      end
    end

    def update(updated_post)
      begin
        @post = updated_post  
        @form = Posts::PostForm.new(@params)   

        if @form.valid?
          post_update_service = Posts::PostService.new(@params)
          response = post_update_service.update(@post)

          if response[:status] == :updated
            return { post: response[:post], status: :updated }
          end
        else
          post = Post.new(@form.attributes)

          post.errors.add(:title, @form.errors[:title]) if @form.errors[:title].any?
          post.errors.add(:content, @form.errors[:content]) if @form.errors[:content].any?
    
          return { post: @form, errors: post.errors, status: :unprocessable_entity }
        end
      rescue StandardError => e
        return {post: post, errors: e.message, status: :unprocessable_entity}
      end
    end

    def destroy(deleted_post)
      begin
       post_delete_service = Posts::PostService.new(@params)
       if post_delete_service.destroy(deleted_post)
        return true
       else
        return false
       end
      rescue StandardError => e
        return { post: @post, errors: e.message, status: :unprocessable_entity}
      end
    end

  end
end