module Bigquery
  class CreateTableJob
    include Sidekiq::Job

    def perform(user_id, project_id, dataset_id, table_id, schema_fields)
      user = User.find_by(id: user_id)
      unless user
        Rails.logger.error("User with ID #{user_id} not found.")
        return
      end

      credentials = GoogleCredentialsService.new(user).credentials
      credentials.fetch_access_token!

      bigquery = Google::Cloud::Bigquery.new(
        project_id: project_id,
        credentials: credentials
      )

      dataset = bigquery.dataset(dataset_id)
      unless dataset
        Rails.logger.error("Dataset '#{dataset_id}' not found in project '#{project_id}'.")
        return
      end

      dataset.create_table(table_id) do |schema|
        schema_fields.each do |field|
          field = field.symbolize_keys
          name = field[:name].to_s.strip
          type = field[:type].to_s.downcase.to_sym

          if name.present? && schema.respond_to?(type)
            schema.send(type, name)
          else
            raise ArgumentError, "Invalid schema field: #{field.inspect}"
          end
        end
      end
    rescue Google::Cloud::AlreadyExistsError
      Rails.logger.warn("Table '#{table_id}' already exists(in create table job).")
    rescue ArgumentError => e
      Rails.logger.error("Argument error: #{e.message} (in create table job).")
    rescue => e
      Rails.logger.error("Failed to create table: #{e.message} (in create table job).")
    end
  end
end
