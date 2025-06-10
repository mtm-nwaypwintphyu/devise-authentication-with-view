module Bigquery
  class IndexUsecase
    def initialize(user)
      # user = local variable
      # @user = instant variable, can be used throughout the class
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
