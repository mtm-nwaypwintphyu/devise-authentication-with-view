require 'google/apis/bigquery_v2'

module Bigquery
  class ShowTableUsecase
    def initialize(user, project_id, dataset_id, table_id: nil)
      @user = user
      @dataset_id = dataset_id
      @table_id = table_id
      @project_id = project_id
    end

    def call
      credentials = GoogleCredentialsService.new(@user).credentials

      bigquery = Google::Cloud::Bigquery.new(
        project_id: @project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(@dataset_id)
      return [] unless dataset

      table = dataset.table(@table_id)
      return { success: true , table_data: table.data.to_a} if table
    rescue Google::Cloud::Error, StandardError => e
      Rails.logger.error("BigQuery Table Data Error: #{e.message}")
      []
    end
  end
end
