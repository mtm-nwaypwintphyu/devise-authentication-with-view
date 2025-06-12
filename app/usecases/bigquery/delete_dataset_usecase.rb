module Bigquery
  class DeleteDatasetUsecase
    def initialize(dataset)
      @dataset = dataset
    end

    def call
      return { success: false, error: "Dataset not found." } if @dataset.blank?

      begin
        # @dataset.delete(force: true)
        @dataset.delete

        { success: true, message: "Dataset '#{@dataset.dataset_id}' is deleted successfully." }

      rescue ArgumentError => e
        { success: false, error: e.message }

      rescue StandardError => e
        { success: false, error: "Unexpected error: #{e.message}" }
      end
    end
  end
end
