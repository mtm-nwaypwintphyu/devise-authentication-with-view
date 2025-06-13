
class BigqueryController < ApplicationController
  before_action :authenticate_user!
  before_action :check_google_tokens
  skip_before_action :verify_authenticity_token, only: [ :create_tables]
  include ::ValidateBigquery

  # get datasets
  def index
    @datasets = Bigquery::IndexUsecase.new(current_user).call
    if @datasets
      @project_id = @datasets.first.project_id
      @datasets
      @error_flg = false
    else
      @datasets = []
    end

  rescue => e
    Rails.logger.error("BigQuery Index Error: #{e.message}")
    flash.now[:alert] = "Failed to load datasets from BigQuery. Please try again  later"
    @error_flg = true
  end
  

  # create dataset form
  def new_create_dataset
    @project_id = params[:project_id]
    
    validate_result = validate_query(current_user.id, project_id: @project_id)
    
    if validate_result[:error]
      flash[:alert] = validate_result[:error]
    else
      flash[:alert] = nil
    end
  end

  def create_dataset
    @project_id = params[:project_id]
    dataset_id = params[:dataset_id]

    validate_result = validate_query(current_user.id, project_id: @project_id)

    if validate_result[:error]
      flash[:alert] = validate_result[:error]
      render :new_create_dataset and return
    end

    usecase = Bigquery::CreateDatasetUsecase.new(current_user, @project_id, dataset_id)
    result = usecase.call

    if result[:success]
      flash[:notice] = result[:message]
      redirect_to bigquery_path
    else
      flash[:alert] = result[:error]
      render :new_create_dataset
    end
  rescue StandardError => e
    flash[:alert] = "Failed to create dataset. Please try again later. #{e}"
    render :new_create_dataset
  end

  # delete dataset
  def delete_dataset
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    
    validate_result = validate_query(current_user.id, project_id: project_id, dataset_id: dataset_id)

    if validate_result[:success] && validate_result[:bigquery]
     @bigquery = validate_result[:bigquery]
     @dataset = @bigquery.dataset(dataset_id)

    else
      flash[:alert] = validate_result[:error]
      redirect_to bigquery_path and return
    end

    usecase = Bigquery::DeleteDatasetUsecase.new(@dataset)
    result = usecase.call

    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:alert] = result[:error]
    end

    redirect_to bigquery_path

  rescue StandardError => e
    flash[:alert] = "Failed to delete dataset. Please try again later. #{e.message}"
    redirect_to bigquery_path
  end


  # get table list
  def tables_index
    @project_id = params[:project_id]
    @dataset_id = params[:dataset_id]
    @tables = []
    @error_flg = false
    
    validate_result = validate_query(current_user.id, project_id: @project_id, dataset_id: @dataset_id)

    unless validate_result[:success] && validate_result[:bigquery]
      flash[:error] = validate_result[:error] || "Validation failed"
      @error_flg = true
      return
    end

    @bigquery = validate_result[:bigquery]
    @dataset = @bigquery.dataset(@dataset_id)
    unless @dataset
      flash[:error] = "Dataset not found or inaccessible"
      @error_flg = true
      return
    end

    usecase = Bigquery::GetTableUsecase.new(@dataset)
    result = usecase.call

    if result[:success]
      @tables = result[:tables]
      @project_id 
      @dataset_id
    else
      flash.now[:error] = result[:error] 
      @error_flg = true
    end
  rescue StandardError => e
    Rails.logger.error("Error in tables_index: #{e.message}")
    flash.now[:alert] = "Failed to load tables from BigQuery. Please try again later."
    @error_flg = true
    @tables = []
  end

  # render to create table form
  def new_create_table
    @dataset_id = params[:dataset_id]
    @project_id = params[:project_id]

    validate_result = validate_query(current_user.id, project_id: @project_id, dataset_id: @dataset_id)
    unless validate_result[:success] 
      flash[:error] = validate_result[:error] || "Validation failed"
      @error_flg = true
      return
    end
  rescue => e
    flash[:alert] = "An unexpected error occurred. Please try again later."
    redirect_to bigquery_path
  end

  # create table
  def create_table
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]
    schema_fields = schema_params[:schema_fields] || []

    validate_result = validate_query(current_user.id, project_id: project_id, dataset_id: dataset_id)

    if validate_result[:error]
      flash[:error] = validate_result[:error]
      redirect_to new_bigquery_create_table_path(project_id, dataset_id) and return
    end

    usecase = Bigquery::CreateTableUsecase.new(
      current_user,
      project_id,
      dataset_id,
      table_id,
      schema_fields
    )

    result = usecase.call
    if result[:success]
      flash[:notice] = result[:message]
      redirect_to bigquery_table_path(project_id, dataset_id)
    else
      flash[:error] = result[:error]
      redirect_to new_bigquery_create_table_path(project_id, dataset_id)
    end
  rescue StandardError => e
    Rails.logger.error("Error in create_table: #{e.message}")
    flash[:error] = "An unexpected error occurred while creating the table. Please try again."
    redirect_to new_bigquery_create_table_path(project_id, dataset_id)
  end

  def upload_table_form
    @project_id = params[:project_id]
    @dataset_id = params[:dataset_id]
    validate_result = validate_query(current_user.id, project_id:  @project_id, dataset_id:  @dataset_id)
    
    unless validate_result[:success] 
      flash[:error] = validate_result[:error] || "Validation failed"
      @error_flg = true
      return
    end

  end

  def upload_table
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]
    csv = params[:csv_file]
    
    validate_result = validate_query(current_user.id, project_id: project_id, dataset_id: dataset_id)
    
    if validate_result[:error]
      redirect_to new_bigquery_create_table_path(project_id,dataset_id) and return
      flash[:error] = result[:error]
    end

    usecase = Bigquery::UploadTableUsecase.new(
      current_user,
      project_id, 
      dataset_id,
      table_id,
      csv
    )

    result = usecase.call
    if result[:success]
      flash[:notice] = result[:message]
      redirect_to bigquery_table_path(project_id, dataset_id)
    else
      flash[:alert] = "Failed. #{result[:error]}"
      redirect_to bigquery_upload_table_path(project_id, dataset_id)
    end
  end


  def show_table
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]
    project_id = params[:project_id]

    result = validate_query(current_user.id, project_id: project_id, dataset_id: dataset_id,table_id: table_id)
    
    if result[:error]
      flash[:error] = result[:error]
      @error_flg = true
    else
      flash[:error] = nil
      @error_flg = false
    end

    usecase = Bigquery::ShowTableUsecase.new(current_user, project_id, dataset_id, table_id: table_id)
      result = usecase.call
      if result[:success]
        @table_data = result[:table_data]
        @error_flg = false
      else
        flash.now[:error] = result[:error]
        @error_flg = false
        @table_data = []
      end
    rescue StandardError => e
      flash.now[:error] = "Failed to load table data from BigQuery. Please try again later"
      @table_data = []
      @error_flg = true
  end

  # delete table
  def delete_table
    project_id = params['project_id']
    dataset_id = params['dataset_id']
    table_id = params['table_id']
    

    validate_result = validate_query(current_user.id, project_id: project_id, dataset_id: dataset_id,table_id: table_id)
    unless validate_result[:success]
      flash[:error] = validate_result[:error] || "Validation failed"
      @error_flg = true
      return
    end

    @bigquery = validate_result[:bigquery]
    @dataset = @bigquery.dataset(dataset_id)
    unless @dataset
      flash[:error] = "Dataset not found or inaccessible"
      @error_flg = true
      return
    end

    @table = @dataset.table(table_id)
    unless @table
      flash[:error] = "Table not found or inaccessible"
      @error_flg = true
      return
    end
    usecase = Bigquery::DeleteTableUsecase.new(@table)
    result = usecase.call
    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:error] = result[:error]
    end

    redirect_to bigquery_table_path(project_id,dataset_id)

  rescue StandardError => e
    flash[:error] = "Failed to delete table. Please try again later. #{e.message}"
    redirect_to bigquery_table_path(project_id,dataset_id)
  end


  def show_schema
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]

    result = validate_query(current_user.id, project_id: project_id, dataset_id: dataset_id,table_id: table_id)
    
    if result[:error]
      flash[:error] = result[:error]
      @error_flg = true
    else
      flash[:error] = nil
      @error_flg = false
    end

    usecase = Bigquery::GetSchemaUsecase.new(
      current_user,
      project_id,
      dataset_id,
      table_id
    )

    result = Bigquery::GetSchemaUsecase.new(current_user, params[:project_id], params[:dataset_id], params[:table_id]).call
    if result[:success]
      @fields = result[:fields]
      @table_id = table_id
      @error_flg = false
    else
      flash[:alert] = result[:error]
    end
  end

  def edit_schema_form
    @project_id = params["project_id"]
    @dataset_id = params["dataset_id"]
    @table_id = params["table_id"]

    validate_result = validate_query(current_user.id, project_id: @project_id, dataset_id: @dataset_id)
    usecase = Bigquery::GetSchemaUsecase.new(
      current_user,
      @project_id,
      @dataset_id,
      @table_id
    )

    result = Bigquery::GetSchemaUsecase.new(current_user, @project_id,  @dataset_id,@table_id).call 
    
    if result[:success]
      @fields = result[:fields]
      @table_id 
      @project_id
      @dataset_id
      @error_flg = false
    else
      flash[:alert] = result[:error]
    end

    result
  rescue => e
    flash[:error] = "An unexpected error occurred. Please try again later.#{e}"
  end

  def update_schema
    @project_id = params[:project_id]
    @dataset_id = params[:dataset_id]
    @table_id = params[:table_id]
    @schema_fields = schema_params[:schema_fields] || []

    validate_result = validate_query(current_user.id, project_id: @project_id, dataset_id: @dataset_id,table_id: @table_id)
    unless validate_result[:success] && validate_result[:bigquery]
      flash[:error] = validate_result[:error] || "Validation failed"
      @error_flg = true
      return
    end

    @bigquery = validate_result[:bigquery]
    @dataset = @bigquery.dataset(@dataset_id)
    unless @dataset
      flash[:error] = "Dataset not found or inaccessible"
      @error_flg = true
      return
    end

    @table = @dataset.table(@table_id)

    unless @table
      flash[:error] = "Table not found or inaccessible"
      @error_flg = true
      return
    end

    usecase = Bigquery::UpdateSchemaUsecase.new(@bigquery,@dataset_id,@table_id,@schema_fields)
    result = usecase.call
    if result[:success]
      flash[:notice] = result[:message]
      redirect_to bigquery_table_path(@project_id, @dataset_id)
    else
      flash[:error] = result[:error]
      redirect_to bigquery_table_schema_edit_form_path(@project_id, @dataset_id)
    end
  rescue StandardError => e
    Rails.logger.error("Error in update_schema: #{e.message}")
    flash[:error] = "An unexpected error occurred while updating the table. Please try again.#{e}"
    redirect_to bigquery_table_schema_edit_form_path(@project_id, @dataset_id)
  end


  private

  def check_google_tokens
    if current_user.google_oauth2_token.blank? || token_expired?
      if current_user.google_oauth2_refresh_token.present?
        unless current_user.refresh_access_token
          redirect_to_google_login and return
        end
      else
        redirect_to_google_login and return
      end
    end
  end

  def token_expired?
    current_user.token_expires_at.nil? || current_user.token_expires_at < Time.current
  end

  def redirect_to_google_login
    redirect_to user_google_oauth2_omniauth_authorize_path 
  end

  def schema_params
    params.permit(schema_fields: [:name, :type])
  end
  
end