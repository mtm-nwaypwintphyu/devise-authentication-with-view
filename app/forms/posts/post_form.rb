module Posts
  class PostForm
    include ActiveModel::Model  

    attr_accessor :title, :content, :user_id  

    validates :title, presence: { message: "Title cannot be empty." }
    validates :content, presence: { message: "Content cannot be empty." }
    validates :user_id, presence: { message: "User must be present" }

    def attributes
      { title: title, content: content, user_id: user_id }
    end

    def to_model
      Post.new(attributes)
    end
  end
end
