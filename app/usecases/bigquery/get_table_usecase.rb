require 'google/apis/bigquery_v2'

module Bigquery
  class GetTableUsecase
    def initialize(dataset)
      @dataset = dataset
    end

    def call
      max = 1000
      all_tables = []
      tables_page = @dataset.tables(max: max)

      loop do
        all_tables.concat(tables_page.to_a)
        break if all_tables.size >= max || !tables_page.next?
        tables_page = tables_page.next
      end

      tables = all_tables.take(max).map do |table|
        {
          table_id: table.table_id,
          dataset_id: table.dataset_id,
          project_id: table.project_id,
          created_at: Time.at(table.gapi.creation_time / 1000),
          table_type: table.type,
          expiration_time: table.gapi.expiration_time ? Time.at(table.gapi.expiration_time / 1000) : nil
        }
      end

      { success: true, tables: tables }

    rescue Google::Cloud::Error => e
      Rails.logger.error("BigQuery Error: #{e.message}") 
      { success: false, error: "BigQuery API error: #{e.message}" }
    rescue => e
      Rails.logger.error("Unexpected error in GetTableUsecase: #{e.message}")
      { success: false, error: "Unexpected error: #{e.message}" }
    end
  end
end
