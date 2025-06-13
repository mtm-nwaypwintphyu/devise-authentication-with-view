module Bigquery
  class UpdateSchemaUsecase
    def initialize(bigquery, dataset_id, table_id, schema_fields = [])
      @bigquery = bigquery
      @dataset_id = dataset_id
      @table_id = table_id
      @schema_fields = sanitize_schema_fields(schema_fields)
    end

    def call
      return error_response("Table ID is required.") unless @table_id
      return error_response("Dataset ID is required.") unless @dataset_id

      dataset = @bigquery.dataset(@dataset_id)
      return error_response("Dataset '#{@dataset_id}' not found.") unless dataset

      table = dataset.table(@table_id)
      return error_response("Table '#{@table_id}' not found.") unless table

      duplicates = find_duplicate_field_names(@schema_fields)
      return error_response("Duplicate field names '#{duplicates.join(', ')}' found.") unless duplicates.empty?

      @existing_fields = table.schema.fields.map { |f| { name: f.name.downcase, type: f.type } }
      service = Bigquery::UpdateSchemaService.new(
        bigquery: @bigquery,
        dataset_id: @dataset_id,
        table_id: @table_id,
        existing_fields: @existing_fields,
        schema_fields: @schema_fields
      )
      result = service.call
      if result[:success] 
        return { success: true, message: result[:message] }
      else
        error_response(result[:error])
      end
    rescue ArgumentError => e
      log_error("Argument error", e)
      error_response(e.message)
    rescue StandardError => e
      log_error("Unexpected error", e)
      error_response("Unexpected error: #{e.message}")
    end

    private
    
    def sanitize_schema_fields(fields)
      fields.map do |field|
        if field.is_a?(ActionController::Parameters)
          field.permit(:name, :type).to_h.symbolize_keys
        elsif field.is_a?(Hash)
          raise ArgumentError, "Missing :name or :type in #{field.inspect}" unless field.key?(:name) && field.key?(:type)
          { name: field[:name], type: field[:type].to_s }
        else
          raise ArgumentError, "Invalid field format: #{field.inspect}"
        end
      end
    end

    def find_duplicate_field_names(fields)
      names = fields.map { |f| f[:name].to_s.strip.downcase }
      names.select { |name| names.count(name) > 1 }.uniq
    end


    def log_error(prefix, error)
      Rails.logger.error("#{prefix} in update schema usecase: #{error.message}")
    end

    def error_response(message)
      { success: false, error: message }
    end
  end
end
