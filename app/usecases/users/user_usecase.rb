require_relative "../../forms/users/user_form.rb"
module Users
  class UserUsecase < BaseUsecase
    def initialize(params)
      @params = params
      @form = Users::UserForm.new(params)
    end
    def update(updated_user)
      begin
        if @form.valid?
          user_update_service = Users::UserService.new(@params)
          response = user_update_service.update(updated_user)
          if response[:status] == :updated
            { user: response[:user], status: :updated }
          else
            { user: response[:user], errors: response[:user].errors.full_messages, status: :unprocessable_entity }
          end
        else
          user = User.new(@form.attributes)
          user.errors.add(:first_name, @form.errors[:first_name]) if @form.errors[:first_name].any?
          user.errors.add(:last_name, @form.errors[:last_name]) if @form.errors[:last_name].any?
          user.errors.add(:email, @form.errors[:email]) if @form.errors[:email].any?
          { user: @form, errors: user.errors, status: :unprocessable_entity }
        end
      rescue StandardError => errors
        { user: @form, errors: errors.message, status: :unprocessable_entity }
      end
    end

    def destroy(user_id)
      begin
        user_delete_service = Users::UserService.new(@params)
        if user_delete_service.destroy(user_id)
          true
        else
          false
        end
      rescue StandardError => errors
        false
      end
    end
  end
end
