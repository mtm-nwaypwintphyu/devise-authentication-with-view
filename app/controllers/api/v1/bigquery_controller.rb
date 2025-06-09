class Api::V1::BigqueryController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    usecase = Bigquery::IndexUsecase.new(current_user)
    @datasets = usecase.call

    render json: {
          message: "Get datasets successfully",
          datasets: @datasets.map { |ds| { id: ds.dataset_id, project_id: ds.project_id } }
        }
  rescue StandardError => e 
    logger.error "BigQuery fetch failed: #{e.message}"
    render json: { error: "Failed to load datasets from BigQuery." }, status: :internal_server_error
  end

  def table_list
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]

    usecase = Bigquery::TableUsecase.new(
      current_user,
      project_id, 
      dataset_id,
      )

    tables = usecase.get_tables

    if tables.present?
      render json: tables
    else
      render json: { error: "Failed to fetch tables" }, status: :internal_server_error
    end
  end

  def show_table
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]

    usecase = Bigquery::TableUsecase.new(current_user, project_id, dataset_id, table_id: table_id)
    @table_data = usecase.get_table_data

    render json: {
      message: "Get tables successfully",
      table_data: @table_data 
    }
  rescue StandardError => e
    logger.error "BigQuery fetch failed: #{e.message}"
    render json: { error: "Failed to load table data from BigQuery." }, status: :internal_server_error
  end

end
