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
      return { success: false, error: "Table ID is empty." } if @table_id.blank?

      duplicates = find_duplicate_field_names(@schema_fields)
      return { success: false, error: "Duplicate field names '#{duplicates.join(', ')}' found." } unless duplicates.empty?

      Bigquery::CreateTableJob.perform_async(
        @user.id,
        @project_id,
        @dataset_id,
        @table_id,
        @schema_fields.map(&:to_h)
      )
      { success: true, message: "Table created successully." }
    rescue ArgumentError => e
      Rails.logger.error("Argument error in create table usecase: #{e.message}")
      { success: false, error: e.message }
    rescue StandardError => e
      Rails.logger.error("Unexpected error in create table usecase: #{e.message}")
      { success: false, error: "Unexpected error: #{e.message}" }
    end


    private

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
