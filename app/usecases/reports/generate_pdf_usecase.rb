module Reports
  class GeneratePdfUsecase
    def self.call
      GeneratePdfReportJob.perform_later
      { success: true , message: "PDF generation started in background. You can download it once ready."}
    end
  end
end
