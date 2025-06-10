require 'csv'   

module Bigquery
  class UploadTableUsecase
    def initialize(user, project_id, dataset_id, table_id, csv)
      @user = user                      
      @project_id = project_id          
      @dataset_id = dataset_id      
      @table_id = table_id             
      @csv_file = csv                   
    end

    def call
      return error_response("Table ID is missing.") if @table_id.blank?
      return error_response("CSV file is missing.") if @csv_file.blank?
      return error_response("Only CSV files are allowed.") unless csv_file_valid?

      csv_data = @csv_file.read
      Bigquery::UploadTableJob.perform_async(
        @user.id,
        @project_id,
        @dataset_id,
        @table_id,
        csv_data
      )

      { success: true, message: "Table upload job has started." }
    rescue => e
      error_response("Unexpected error: #{e.message}")
    end

    private

    def csv_file_valid?
      File.extname(@csv_file.original_filename).casecmp('.csv').zero?
    end

    def error_response(message)
      { success: false, error: message }
    end
  end
end
