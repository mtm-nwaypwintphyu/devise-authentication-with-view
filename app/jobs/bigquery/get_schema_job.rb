module Bigquery
  class GetSchemaJob
    include Sidekiq::Job

    def perform(user_id,project_id,dataset_id,table_id)
      user = User.find_by(id: user_id)

      credentials = GoogleCredentialsService.new(user).credentials
        credentials.fetch_access_token!

        bigquery = Google::Cloud::Bigquery.new(
          project_id: project_id,
          credentials: credentials
        )

        dataset = bigquery.dataset(dataset_id)
        
        return [] unless dataset

        table = dataset.table(table_id)
        return [] unless table

        fields = extract_fields_nested(table.schema.fields).to_a

        Rails.cache.write(cache_key(user_id,project_id,dataset_id,table_id), fields, expires_in: 1.minutes)

    end
    
    private

    def extract_fields_nested(fields)
      fields.map do |field|
        result = {
          name: field.name,
          type: field.type,
          mode: field.mode
        }

        if field.type == "RECORD"
          result[:fields] = extract_fields_nested(field.fields)
        end

        result
      end
    end

    def cache_key(user_id, project_id, dataset_id, table_id)
      "table_schema_#{user_id}_#{project_id}_#{dataset_id}_#{table_id}"
    end

  end
end