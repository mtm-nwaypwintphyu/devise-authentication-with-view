module Bigquery
  class ShowTableJob
    include Sidekiq::Job

    def perform(user_id,project_id,dataset_id,table_id)
      user = User.find_by(id: user_id)
      credentials = GoogleCredentialsService.new(user).credentials

      bigquery = Google::Cloud::Bigquery.new(
        project_id: project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(dataset_id)
      return [] unless dataset

      table = dataset.table(table_id).data.to_a
      
      Rails.cache.write(cache_key(user_id,project_id,dataset_id,table_id), table, expires_in: 1.minutes)
      
    end

    private
    
    def cache_key(user_id,project_id,dataset_id,table_id)
      "show_table_#{user_id}_#{project_id}_#{dataset_id}_#{table_id}"
    end
  end
end