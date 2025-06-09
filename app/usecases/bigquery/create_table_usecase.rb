module Bigquery
  class CreateTableUsecase

    def initialize(user, project_id, dataset_id, table_id, schema_fields = [])
      @user = user
      @project_id = project_id
      @dataset_id = dataset_id
      @table_id = table_id
      @schema_fields = schema_fields
    end

    def call
      return { success: false, error: "Table ID is empty." } if @table_id.blank?

      field_names = @schema_fields.map { |f| f[:name].to_s.strip }
      duplicates = field_names.select { |name| field_names.count(name) > 1 }.uniq
      unless duplicates.empty?
        return { success: false, error: "Duplicate field names '#{duplicates.join(', ')}'  found." }
      end

      credentials = GoogleCredentialsService.new(@user).credentials
      credentials.fetch_access_token!

      bigquery = Google::Cloud::Bigquery.new(
        project_id: @project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(@dataset_id)
      return { success: false, error: "Dataset not found." } unless dataset

      table = dataset.create_table(@table_id) do |schema|
        @schema_fields.each do |field|
          field = field.to_h.symbolize_keys
          name = field[:name].to_s.strip
          type = field[:type].to_s.downcase.to_sym

          if name.present? && schema.respond_to?(type)
            schema.send(type, name)
          else
            raise ArgumentError, "Invalid schema field: #{field.inspect}"
          end
        end
      end

      { success: true, table: table }

    rescue Google::Cloud::AlreadyExistsError
      { success: false, error: "The table '#{@table_id}' already exists in dataset '#{@dataset_id}'." }

    rescue Google::Cloud::Error => e
      { success: false, error: "Google Cloud error: #{e.message}" }

    rescue ArgumentError => e
      { success: false, error: e.message }

    rescue StandardError => e
      { success: false, error: "Unexpected error: #{e.message}" }
    end
  end
end
