require 'csv'

module Bigquery
  class UploadTableJob
    include Sidekiq::Job

    def perform(user_id, project_id, dataset_id, table_id, csv_data)
      user = User.find_by(id: user_id)
      return unless user

      credentials = GoogleCredentialsService.new(user).credentials
      credentials.fetch_access_token!

      bigquery = Google::Cloud::Bigquery.new(
        project_id: project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(dataset_id)
      return unless dataset

      csv_file = StringIO.new(csv_data)
      headers = CSV.parse(csv_data, headers: true).headers
      return if headers.blank?

      table = create_table_with_schema(dataset, table_id, headers)
      return unless table

      csv_file.rewind
      job = table.load_job(csv_file, format: :csv, write: 'WRITE_APPEND', autodetect: false)
      job.wait_until_done!

      raise "Load job failed: #{job.error}" if job.failed?
    end

    private

    def create_table_with_schema(dataset, table_id, headers)
      dataset.create_table(table_id) do |schema|
        headers.each do |header|
          schema.string header, mode: :nullable
        end
      end
    rescue Google::Cloud::AlreadyExistsError
      dataset.table(table_id) 
    end
  end
end
