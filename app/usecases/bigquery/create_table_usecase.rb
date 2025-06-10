module Bigquery
  class CreateTableUsecase
    def initialize(user, project_id, dataset_id, table_id, schema_fields = [])
      @user = user
      @project_id = project_id
      @dataset_id = dataset_id
      @table_id = table_id
      @schema_fields = sanitize_schema_fields(schema_fields)
    end

    def call
      return failure("Table ID is empty.") if @table_id.blank?

      duplicates = find_duplicate_field_names(@schema_fields)
      return failure("Duplicate field names '#{duplicates.join(', ')}' found.") unless duplicates.empty?

      Bigquery::CreateTableJob.perform_async(
        @user.id,
        @project_id,
        @dataset_id,
        @table_id,
        @schema_fields.map(&:to_h) 
      )

      success("Table creation is running in background.")
    rescue ArgumentError => e
      failure(e.message)
    rescue StandardError => e
      failure("Unexpected error: #{e.message}")
    end

    private

    def success(message)
      { success: true, message: message }
    end

    def failure(error)
      { success: false, error: error }
    end

    def sanitize_schema_fields(fields)
      fields.map do |field|
        if field.is_a?(ActionController::Parameters)
          field.permit(:name, :type).to_h
        else
          raise ArgumentError, "Invalid field format: #{field.inspect}"
        end
      end
    end

    def find_duplicate_field_names(fields)
      names = fields.map { |f| f[:name].to_s.strip }
      names.select { |name| names.count(name) > 1 }.uniq
    end
  end
end
