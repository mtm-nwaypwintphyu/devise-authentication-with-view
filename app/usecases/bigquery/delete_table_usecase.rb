module Bigquery
  class DeleteTableUsecase
    def initialize(table)
      @table = table
    end

    def call
      return { success: false, error: "Table not found." } if @table.blank?

      begin
        @table.delete

        { success: true, message: "Table '#{@table.table_id}' is deleted successfully." }
      rescue ArgumentError => e
        { success: false, error: e.message }
      rescue StandardError => e
        { success: false, error: "Unexpected error: #{e.message}" }
      end
    end
  end
end
