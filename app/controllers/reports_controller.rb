class ReportsController < ApplicationController
  before_action :authenticate_user!
  def generate_pdf
    if result[:success]
      redirect_to posts_path
    else
      redirect_to posts_path, notice: "Faild to start PDF generation"
    end
  end

  def download_pdf
    result = Reports::DownloadPdfUsecase.call
    if result[:success]
      AnalyticsEventCreateJob.perform_async(
        current_user.id,
        'download pdf file',
        {
          'download user' => current_user.first_name + " "+ current_user.last_name,
          'pdf title' => "Post information pdf"
        }
      )
      send_file result[:file_path],
                type: 'application/pdf',
                disposition: 'attachment',
                filename: result[:filename]
    else
      redirect_to posts_path, alert: result[:message]
    end
  end

  def download_excel
    result = Reports::DownloadExcelUsecase.call
    if result[:success]
       AnalyticsEventCreateJob.perform_async(
        current_user.id,
        'download excel file',
        {
          'download user' => current_user.first_name + " "+ current_user.last_name,
          'excle file title' => "User information excle file"
        }
      )
      send_file result[:file_path],
                      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                      filename: result[:file_name]
    else
      redirect_to users_path, notice: result[:message]
    end
  end

end
