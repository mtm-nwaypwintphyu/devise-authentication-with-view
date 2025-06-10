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
      key = cache_key(@user.id,@project_id,@dataset_id,@table_id)
      table = Rails.cache.read(key)
      unless table
        Bigquery::ShowTableJob.perform_async(@user.id,@project_id,@dataset_id,@table_id)
        return []
      end

      table

    rescue Google::Cloud::Error, StandardError => e
      Rails.logger.error("BigQuery Table Data Error: #{e.message}")
      []
    end

    private

    def cache_key(user_id,project_id,dataset_id,table_id)
      "show_table_#{user_id}_#{project_id}_#{dataset_id}_#{table_id}"
    end
  end
end
