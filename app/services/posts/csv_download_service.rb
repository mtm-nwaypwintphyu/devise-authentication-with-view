require 'csv'

module Posts
  class CsvDownloadService
    def initialize(posts)
      @posts = posts
    end

    def process

      if @posts.blank?
        raise 'No posts available for CSV download.'
      end

      formatted_posts = @posts.map do |post|
        {
          id: post.id,
          title: post.title,
          content: post.content,
          created_at: post.created_at,
          updated_at: post.updated_at,
          user_id: post.user_id
        }
      end

      CSV.generate(headers: true) do |csv|
        csv << ["ID", "Title", "Content", "Created At", "Updated At", "User ID"]
        formatted_posts.each do |post|
          csv << [
            post[:id], post[:title], post[:content],
            post[:created_at], post[:updated_at], post[:user_id]
          ]
        end
      end
      
    end
  end
end
