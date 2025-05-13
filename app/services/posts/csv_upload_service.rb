class Posts::CsvUploadService
  require 'csv'

  def self.call(csv_file, user)
    new(csv_file, user).process
  end
  MAX_FILE_SIZE = 2 * 1024 * 1024 

  def initialize(csv_file,user)
    @csv_file = csv_file
    @user = user
  end

  def process
    csv_file_path = @csv_file.path


    unless File.extname(csv_file_path).downcase == '.csv'
      return Result.error("Invalid file type. Please upload a CSV file.")
    end

    if File.size(@csv_file.path) > MAX_FILE_SIZE
      return Result.error("File size exceeds the 2MB limit.")
    end

    begin
      CSV.foreach(csv_file_path, headers: true) do |row|
        Post.create!(
          title: row["Title"],
          content: row["Content"],
          user_id: @user.id
        )
      end
      return Result.success
    rescue => e
     return Result.error("An error occurred when processing the CSV file: #{e.message}")
    end
  end
end