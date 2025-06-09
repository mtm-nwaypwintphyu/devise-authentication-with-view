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

     
      credentials = GoogleCredentialsService.new(@user).credentials
      credentials.fetch_access_token!  

      bigquery = Google::Cloud::Bigquery.new(
        project_id: @project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(@dataset_id)
      return error_response("Dataset not found.") unless dataset

      headers = extract_headers
      return error_response("CSV must have headers.") if headers.blank?

      table = create_table_with_schema(dataset, headers)
      return error_response("Table with id: '#{@table_id}' already exists.") unless table

      @csv_file.rewind 

      job = table.load_job(@csv_file.tempfile, format: :csv, write: 'WRITE_APPEND', autodetect: false)
      job.wait_until_done! 
     
      return error_response("Load job failed: #{job.error}") if job.failed?

      { success: true, table: table }

    rescue Google::Cloud::Error => e
      error_response("Google Cloud error: #{e.message}")
    rescue => e
      error_response("Unexpected error: #{e.message}")
    end

    private

    def csv_file_valid?
      File.extname(@csv_file.original_filename).casecmp('.csv').zero?
    end

    def extract_headers
      @csv_file.rewind
      csv_text = @csv_file.read
      CSV.parse(csv_text, headers: true).headers
    end

    def create_table_with_schema(dataset, headers)
      dataset.create_table(@table_id) do |schema|
        headers.each do |header|
          schema.string header, mode: :nullable 
        end
      end
    rescue Google::Cloud::AlreadyExistsError
      nil  
    end

    def error_response(message)
      { success: false, error: message }
    end
  end
end
