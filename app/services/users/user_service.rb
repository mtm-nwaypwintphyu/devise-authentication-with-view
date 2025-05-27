module Users
  class UserService
    def initialize(params)
      @params = params
    end

    def update(updated_user)
      user = User.new(@params)
      if updated_user.update(@params)
        { user: updated_user, status: :updated }
      else
        { user: updated_user, status: :unprocessable_entity }
      end
    end

    def destroy(user_id)
      user = User.find_by(id: user_id)
      return false unless user

      user.destroy
      user.destroyed?
    rescue => e
      Rails.logger.error "Failed to delete user: #{e.message}"
      false
    end
  end
end
