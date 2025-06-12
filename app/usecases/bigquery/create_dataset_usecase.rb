module Bigquery
  class CreateDatasetUsecase
    def initialize(user, project_id, dataset_id)
      @user = user
      @project_id = project_id
      @dataset_id = dataset_id
    end

    def call
      return { success: false, error: "User not found" } unless @user
      return { success: false, error: "Dataset id is missing." } unless @dataset_id

      begin
        credentials = GoogleCredentialsService.new(@user).credentials
        credentials.fetch_access_token!

        bigquery = Google::Cloud::Bigquery.new(
          project_id: @project_id,
          credentials: credentials
        )

        dataset = bigquery.create_dataset(@dataset_id)
        
        if dataset
          { success: true, message: "Dataset '#{@dataset_id}' created successfully." }
        else
          { success: false, error: "Dataset creation returned no result." }
        end

      rescue ArgumentError => e
        { success: false, error: e.message }

      rescue StandardError => e
        { success: false, error: "Unexpected error: #{e.message}" }
      end
    end
  end
end
