module Users
  class UserForm < BaseForm
    VirtusMixin = Virtus.model
    include VirtusMixin
    include ActiveModel::Validations

    attribute :first_name, String
    attribute :last_name, String
    attribute :email, String
    attribute :password, String
    attribute :password_confirmation, String

    validates :first_name, presence: { message: "First Name cannot be empty." }
    validates :last_name, presence: { message: "Last Name cannot be empty." }
    validates :email, presence: { message: "Email cannot be empty." }
    validates :password, presence: { message: "Password cannot be empty." }, on: :create
    validates :password_confirmation, presence: { message: "Password Confirmation cannot be empty." }, if: -> { password.present? }
  end
end
