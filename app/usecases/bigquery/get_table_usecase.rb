require 'google/apis/bigquery_v2'

module Bigquery
  class GetTableUsecase
    def initialize(user, project_id, dataset_id)
      @user = user
      @dataset_id = dataset_id
      @project_id = project_id
    end

    def call
      credentials = GoogleCredentialsService.new(@user).credentials
      credentials.fetch_access_token!

      bigquery = Google::Cloud::Bigquery.new(
        project_id: @project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(@dataset_id)
      return [] unless dataset

      max = 200
      all_tables = []
      tables_page = dataset.tables(max: max)
      
      loop do
        all_tables.concat(tables_page.to_a)
        break if all_tables.size >= max || !tables_page.next?
        tables_page = tables_page.next
      end

      all_tables.take(max).map do |table|
        {
          table_id: table.table_id,
          dataset_id: table.dataset_id,
          project_id: table.project_id,
          created_at: Time.at(table.gapi.creation_time / 1000),
          table_type: table.type,
          expiration_time: table.gapi.expiration_time ? Time.at(table.gapi.expiration_time / 1000) : nil
        }
      end

    rescue Google::Cloud::Error => e
      Rails.logger.error("BigQuery Error: #{e.message}")
      []
    end
  end
end
