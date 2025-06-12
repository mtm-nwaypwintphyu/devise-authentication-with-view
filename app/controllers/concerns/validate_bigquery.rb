module ValidateBigquery
  def validate_query(user_id, project_id: nil, dataset_id: nil, table_id: nil)
    user = User.find_by(id: user_id)
    return { success: false, error: "User not found" } unless user

    credentials = begin
      creds = GoogleCredentialsService.new(user).credentials
      creds.fetch_access_token!
      creds
    rescue => e
      return { success: false, error: "Invalid Google credentials: #{e.message}" }
    end

    bigquery = nil
    if project_id.present?
      bigquery = begin
        client = Google::Cloud::Bigquery.new(project_id: project_id, credentials: credentials)
        client.datasets 
        client
      rescue => e
        return { success: false, error: "Invalid project ID." }
      end
    end

    dataset = nil
    if dataset_id.present?
      dataset = begin
        bigquery.dataset(dataset_id)
      rescue => e
        return { success: false, error: "Dataset check failed: #{e.message}" }
      end

      return { success: false, error: "Invalid dataset ID or inaccessible dataset." } unless dataset
    end
    
    if table_id.present?
      table = begin
        dataset.table(table_id)
      rescue => e
        return { success: false, error: "Table check failed: #{e.message}" }
      end

      return { success: false, error: "Table not found." } unless table
    end

    { success: true, bigquery: bigquery, dataset: dataset }
  end
end
