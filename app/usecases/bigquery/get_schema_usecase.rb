module Bigquery
  class GetSchemaUsecase
    def initialize(user, project_id, dataset_id, table_id)
      @user = user
      @project_id = project_id
      @dataset_id = dataset_id
      @table_id = table_id
    end

    def call
      begin
        credentials = GoogleCredentialsService.new(@user).credentials
        credentials.fetch_access_token!

        bigquery = Google::Cloud::Bigquery.new(
          project_id: @project_id,
          credentials: credentials
        )

        dataset = bigquery.dataset(@dataset_id)
        return { success: false, error: "Dataset not found." } unless dataset

        table = dataset.table(@table_id)
        return { success: false, error: "Table not found." } unless table

        fields = extract_fields_nested(table.schema.fields)

        return { success: true, fields: fields }

      rescue Google::Cloud::Error => e
        return { success: false, error: "BigQuery API error: #{e.message}" }
      rescue => e
        return { success: false, error: "Unexpected error: #{e.message}" }
      end
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

  end
end
