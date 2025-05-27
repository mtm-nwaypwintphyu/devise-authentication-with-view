module Reports
  class DownloadPdfUsecase
    def self.call
      file_path = Rails.root.join("public", "post_report.pdf")

      if File.exist?(file_path)
        { success: true, file_path: file_path, filename: "post_report.pdf" }
      else
        { success: false, message: "File path does not exist" }
      end
    end
  end
end
