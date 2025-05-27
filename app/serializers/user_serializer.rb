class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email


  def created_at
    created_at = object.created_at.strftime("%m-%d-%y")
  end

  def updated_at
    updated_at = object.updated_at.strftime("%m-%d-%y")
  end
end
