class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.all.decorate
  end

  def show
    @user = User.find(params[:id]).decorate
  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.html do
        redirect_to users_path, notice: "User not found."
      end
      format.json do
        render json: { error: "User not found", message: e.message }, status: :not_found
      end
    end
  end


  def edit 
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    @user_usecase = Users::UserUsecase.new(user_params)
    response = @user_usecase.update(@user)
    respond_to do |format|
      if response[:status] == :updated
       AnalyticsEventCreateJob.perform_async(
          current_user.id,
          'user update',
          {
            'user_id' => @user.id,
            'first_name' => @user.first_name,
            'last_name' => @user.last_name,
            'email' => @user.email
          }
        )
        format.html { redirect_to users_url, notice: "User updated successfully." }
        format.json { render :show, status: :ok, location: @user }
      else
        @user.errors.add(:first_name, response[:errors][:first_name]) if response[:errors][:first_name]
        @user.errors.add(:last_name, response[:errors][:last_name]) if response[:errors][:last_name]
        @user.errors.add(:email, response[:errors][:email]) if response[:errors][:email]
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    @usecase = Users::UserUsecase.new(nil)
    respond_to do |format|
      if @usecase.destroy(params[:id])
        AnalyticsEventCreateJob.perform_async(
          current_user.id,
          'user delete',
          {
            'user_id' => @user.id,
            'first_name' => @user.first_name,
            'last_name' => @user.last_name,
            'email' => @user.email
          }
        )
        format.html { redirect_to users_url, notice: "User deleted successfully." } 
        format.json { render :show, status: :ok, location: @user }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

end
