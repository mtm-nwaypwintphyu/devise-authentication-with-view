require 'google/apis/bigquery_v2'

module Bigquery
  class TableUsecase
    def initialize(user,project_id, dataset_id, table_id: nil)
      @user = user
      @dataset_id = dataset_id
      @table_id = table_id
      @project_id = project_id
    end

    # ==============
    def get_tables
      credentials = GoogleCredentialsService.new(@user).credentials
      credentials.fetch_access_token!

      bigquery = Google::Cloud::Bigquery.new(
        project_id: @project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(@dataset_id)
      return [] unless dataset

      max = 150
      all_tables = []
      tables_page = dataset.tables(max: max)
      
      loop do
        all_tables.concat(tables_page.to_a)

        # stop when size > max
        break if all_tables.size >= max

        # stop when there is no next page
        break unless tables_page.next?

        tables_page = tables_page.next
      end

      all_tables.take(max).map do |table|
        {
          table_id: table.table_id,
          dataset_id: table.dataset_id,
          project_id: table.project_id,
          created_at: Time.at(table.gapi.creation_time / 1000), 
          table_type: table.type,
          project_id: table.project_id,
          expiration_time: table.gapi.expiration_time ? Time.at(table.gapi.expiration_time / 1000) : nil
        }
      end

    rescue Google::Cloud::Error => e
      Rails.logger.error("BigQuery Error: #{e.message}")
      []
    end

    # ===============

    def get_table_data
      credentials = GoogleCredentialsService.new(@user).credentials

      bigquery = Google::Cloud::Bigquery.new(
        project_id: @project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(@dataset_id)

      return [] unless dataset
      
      table = bigquery.dataset(@dataset_id).table(@table_id)
      table ? table.data.to_a : []
    rescue Google::Cloud::Error, StandardError => e
      Rails.logger.error("BigQuery Table Data Error: #{e.message}")
      []
    end
end
end
