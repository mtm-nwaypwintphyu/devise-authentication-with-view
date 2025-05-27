module Reports
  class DownloadExcelUsecase
    def self.call
    file_path = Rails.root.join("tmp", "user_report.xlsx")
      if File.exist?(file_path)
        { success: true, file_path: file_path, filename: "user_report.pdf" }
      else
        { success: false, message: "File path does not exist" }
      end
    end
  end
end
