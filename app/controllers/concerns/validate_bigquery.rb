module ValidateBigquery
  def validate_query(user_id, project_id, dataset_id, table_id: nil)
    user = User.find_by(id: user_id)
    return { error: "User not found" } unless user

    begin
      credentials = GoogleCredentialsService.new(user).credentials
      credentials.fetch_access_token!
    rescue => e
      return { error: "Invalid Google credentials: #{e.message}" }
    end

    begin
      bigquery = Google::Cloud::Bigquery.new(
        project_id: project_id,
        credentials: credentials
      )

      bigquery.datasets
    rescue => e
      return { error: "Invalid project ID." }
    end

    begin
      dataset = bigquery.dataset(dataset_id)
      return { error: "Invalid dataset ID or inaccessible dataset." } unless dataset
    rescue => e
      return { error: "Dataset check failed: #{e.message}" }
    end

    if table_id.present?
      begin
        table = dataset.table(table_id)
        return { error: "Table not found." } unless table
      rescue => e
        return { error: "Table check failed: #{e.message}" }
      end
    end
    { success: true }
  end
end
