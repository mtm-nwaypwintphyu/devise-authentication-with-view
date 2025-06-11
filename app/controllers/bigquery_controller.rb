
class BigqueryController < ApplicationController
  before_action :authenticate_user!
  before_action :check_google_tokens
  skip_before_action :verify_authenticity_token, only: [ :create_tables]
  skip_before_action :authenticate_user!, only: [:create_tables]
  skip_before_action :check_google_tokens, only: [:create_tables]
  include ::ValidateBigquery

  # get datasets
  def index
    @datasets = Bigquery::IndexUsecase.new(current_user).call
    if @datasets
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

  # =============== test create tables api 
  def create_tables
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]

    begin
      user = User.find_by(email: "mtm.nwaypwintphyu@gmail.com")
      credentials = GoogleCredentialsService.new(user).credentials
      bigquery = Google::Cloud::Bigquery.new(credentials: credentials, project: project_id)
      dataset = bigquery.dataset(dataset_id)

      100.times do |i|
        table_id = "table_#{i + 01}"
        dataset.create_table(table_id) do |t|
          t.schema.string "name"
        end
      end
      render json: { message: "Created 100 tables in project #{project_id}, dataset #{dataset_id}" }, status: :ok
    rescue Google::Cloud::Error, StandardError => e
      Rails.logger.error("BigQuery error: #{e.message}")
      render json: { error: "Failed: #{e.message}" }, status: :internal_server_error
    end
  end

  # render to create table form
  def new_create_table
    @dataset_id = params[:dataset_id]
    @project_id = params[:project_id]
    
    validate_result = validate_query(current_user.id, @project_id, @dataset_id)
    
    if validate_result[:error]
      flash[:alert] = validate_result[:error]
    else
      flash[:alert] = nil
    end
  end

  # table create
  def create_table
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]
    schema_fields = schema_params[:schema_fields] || []

    validate_result = validate_query(current_user.id, project_id, dataset_id)
    
    if validate_result[:error]
      redirect_to new_bigquery_create_table_path(project_id,dataset_id) and return
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
      flash[:alert] = "Failed to create table #{table_id}. #{result[:error]}"
      redirect_to new_bigquery_create_table_path(project_id, dataset_id)
    end
  end


  def upload_table_form
    @project_id = params[:project_id]
    @dataset_id = params[:dataset_id]
    validate_result = validate_query(current_user.id, @project_id, @dataset_id)
    
    if validate_result[:error]
      flash[:alert] = validate_result[:error]
    else
      flash[:alert] = nil
    end
  end

  def upload_table
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]
    csv = params[:csv_file]
    
    validate_result = validate_query(current_user.id, project_id, dataset_id)
    
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

  def tables_index
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    @error_flg = nil
    
    validate_result = validate_query(current_user.id, project_id, dataset_id)
    if validate_result[:error]
      flash[:error] = validate_result[:error]
      @error_flg = true
      @tables = []
      return
    else
      flash[:error] = nil
      @error_flg = false
    end

    usecase = Bigquery::GetTableUsecase.new(
      current_user,
      project_id, 
      dataset_id
      )

    result = usecase.call
    if result[:success]
      @tables = result[:tables]
      @error_flg = false
    else
      flash.now[:error] = result[:error]
      @error_flg = true
      @tables = []
    end
  rescue StandardError => e
    flash.now[:alert] = "Failed to load tables from BigQuery. Please try again later. #{e}"
    @tables = []
    @error_flg = true
  end


  def show_table
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]
    project_id = params[:project_id]

    result = validate_query(current_user.id, project_id, dataset_id,table_id: table_id)
    
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
      flash.now[:alert] = "Failed to load table data from BigQuery. Please try again later"
      @table_data = []
      @error_flg = true
  end

  def show_schema
    project_id = params[:project_id]
    dataset_id = params[:dataset_id]
    table_id = params[:table_id]

    result = validate_query(current_user.id, project_id, dataset_id,table_id: table_id)
    
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
    p "hello"
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