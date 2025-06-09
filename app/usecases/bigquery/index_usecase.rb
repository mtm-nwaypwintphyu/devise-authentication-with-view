module Bigquery
  class IndexUsecase
    def initialize(user)
      @user = user
    end

    def call
      credentials = GoogleCredentialsService.new(@user).credentials
      credentials.fetch_access_token! 
      
      bigquery = Google::Cloud::Bigquery.new(credentials: credentials)
      bigquery.datasets.all
    rescue Google::Cloud::Error => e
      Rails.logger.error("BigQuery Error: #{e.message}")
      []
    end
  end
end
