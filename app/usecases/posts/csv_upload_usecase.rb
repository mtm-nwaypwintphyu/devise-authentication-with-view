module Posts
  class CsvUploadUsecase
    def initialize(csv_file,user)
      @csv_file = csv_file
      @user = user
    end

    def execute
      Posts::CsvUploadService.new(@csv_file,@user).process
    end

  end
end